# src/app/main.py
from datetime import datetime
from typing import Optional, List
import os
import logging
import traceback
import time
from sqlalchemy.exc import IntegrityError, OperationalError

from flask import Flask, Request, Response, abort, render_template, redirect, url_for, request
from flask_sqlalchemy import SQLAlchemy
from google.cloud.logging import Client
from markupsafe import escape
from sqlalchemy.engine.url import URL
from sqlalchemy import text
from waitress import serve

class StatusAwareHandler(logging.Handler):
    def __init__(self, gcp_handler):
        super().__init__()
        self.gcp_handler = gcp_handler
        
    def emit(self, record):
        if hasattr(record, 'status_code'):
            status_code = record.status_code
            if status_code >= 500:
                record.levelno = logging.ERROR
                record.levelname = 'ERROR'
            elif status_code == 404:
                record.levelno = logging.INFO
                record.levelname = 'INFO'
            elif status_code >= 400:
                record.levelno = logging.WARNING
                record.levelname = 'WARNING'
        
        self.gcp_handler.emit(record)

def setup_logging() -> None:
    try:
        from google.cloud.logging import Client
        client = Client()
        client.setup_logging()

        # Configure Waitress logging
        waitress_logger = logging.getLogger('waitress')
        waitress_logger.setLevel(logging.INFO)
        waitress_logger.propagate = False
        waitress_logger.addHandler(StatusAwareHandler(client.get_default_handler()))
    except Exception as e:
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s %(levelname)s %(name)s %(message)s'
        )
        logging.warning(
            f"Using default logging setup due to error: {str(e)}"
        )

setup_logging()
logger = logging.getLogger('todo_app')

app = Flask(__name__)

# Database configuration with proper URL construction
db_config = {
    'drivername': 'postgresql',
    'username': os.getenv('DB_USER', 'todo_app_user'),
    'password': os.getenv('DB_PASSWORD', 'localdev'),
    'host': os.getenv('DB_HOST', 'localhost'),
    'database': os.getenv('DB_NAME', 'todos'),
    'query': {'sslmode': 'disable'}
}

app.config['SQLALCHEMY_DATABASE_URI'] = URL.create(**db_config)
app.config['SQLALCHEMY_TRACK_MODIFICATIONS'] = False

db = SQLAlchemy()
db.init_app(app)

class Todo(db.Model):
    """Todo item model."""
    __tablename__ = 'todos'
    __table_args__ = {'schema': 'todo_app'}

    id: int = db.Column(db.Integer, primary_key=True)
    title: str = db.Column(db.String(200), nullable=False)
    created_at: datetime = db.Column(
        db.DateTime(timezone=True),
        default=datetime.utcnow,
        nullable=False
    )
    completed: bool = db.Column(db.Boolean, default=False, nullable=False)

    def __repr__(self) -> str:
        return f'<Todo {self.id}: {self.title}>'

    @classmethod
    def get_all(cls) -> List['Todo']:
        """Retrieve all todos ordered by creation date."""
        try:
            todos = cls.query.order_by(cls.created_at.desc()).all()
            logger.info(
                "Retrieved all todos",
                extra={
                    'component': 'database',
                    'operation': 'get_all',
                    'count': len(todos)
                }
            )
            return todos
        except Exception as e:
            logger.error(
                "Failed to retrieve todos",
                extra={
                    'component': 'database',
                    'operation': 'get_all',
                    'error': str(e),
                    'traceback': traceback.format_exc()
                }
            )
            raise

    @classmethod
    def get_by_id(cls, todo_id: int) -> Optional['Todo']:
        """Retrieve a todo by its ID."""
        try:
            todo = cls.query.get(todo_id)
            logger.info(
                f"Retrieved todo by id {todo_id}",
                extra={
                    'component': 'database',
                    'operation': 'get_by_id',
                    'todo_id': todo_id,
                    'found': bool(todo)
                }
            )
            return todo
        except Exception as e:
            logger.error(
                f"Failed to retrieve todo {todo_id}",
                extra={
                    'component': 'database',
                    'operation': 'get_by_id',
                    'todo_id': todo_id,
                    'error': str(e),
                    'traceback': traceback.format_exc()
                }
            )
            raise

    def save(self) -> None:
        """Save the current todo item."""
        try:
            db.session.add(self)
            db.session.commit()
            logger.info(
                "Saved todo item",
                extra={
                    'component': 'database',
                    'operation': 'save',
                    'todo_id': self.id,
                    'title': self.title
                }
            )
        except Exception as e:
            logger.error(
                "Failed to save todo",
                extra={
                    'component': 'database',
                    'operation': 'save',
                    'title': self.title,
                    'error': str(e),
                    'traceback': traceback.format_exc()
                }
            )
            db.session.rollback()
            raise

    def delete(self) -> None:
        """Delete the current todo item."""
        try:
            db.session.delete(self)
            db.session.commit()
            logger.info(
                "Deleted todo item",
                extra={
                    'component': 'database',
                    'operation': 'delete',
                    'todo_id': self.id
                }
            )
        except Exception as e:
            logger.error(
                "Failed to delete todo",
                extra={
                    'component': 'database',
                    'operation': 'delete',
                    'todo_id': self.id,
                    'error': str(e),
                    'traceback': traceback.format_exc()
                }
            )
            db.session.rollback()
            raise

    def toggle_completion(self) -> None:
        """Toggle the completion status of the todo item."""
        try:
            self.completed = not self.completed
            db.session.commit()
            logger.info(
                "Toggled todo completion",
                extra={
                    'component': 'database',
                    'operation': 'toggle',
                    'todo_id': self.id,
                    'completed': self.completed
                }
            )
        except Exception as e:
            logger.error(
                "Failed to toggle todo",
                extra={
                    'component': 'database',
                    'operation': 'toggle',
                    'todo_id': self.id,
                    'error': str(e),
                    'traceback': traceback.format_exc()
                }
            )
            db.session.rollback()
            raise

@app.before_request
def before_request():
    """Log incoming requests."""
    logger.info(
        "Received request",
        extra={
            'component': 'http',
            'method': request.method,
            'path': request.path,
            'remote_addr': request.remote_addr,
        }
    )

@app.route('/', methods=['GET'])
def index() -> str:
    """Display the main page with all todos."""
    try:
        todos = Todo.get_all()
        return render_template('index.html', todos=todos)
    except Exception as e:
        logger.error(f"Failed to load index page: {e}")
        # Return a proper error page instead of letting it propagate to default
        return render_template('error.html', error="Failed to load todos"), 500


@app.route('/add', methods=['POST'])
def add() -> Response:
    """Add a new todo item."""
    title = request.form.get('title', '').strip()
    if title and len(title) <= 200:
        # Escape HTML in the title
        safe_title = escape(title)
        todo = Todo(title=safe_title)
        try:
            todo.save()
            logger.info(
                "Created new todo",
                extra={
                    'component': 'http',
                    'operation': 'create',
                    'title_length': len(safe_title)
                }
            )
        except IntegrityError as e:
            logger.error("Failed to save todo due to data constraint", extra={'error': str(e)})
            return "Todo too long", 400
    return redirect(url_for('index'))

@app.route('/toggle/<int:id>')
def toggle(id: int) -> Response:
    """Toggle completion status of a todo item."""
    todo = Todo.get_by_id(id)
    if todo:
        todo.toggle_completion()
    return redirect(url_for('index'))

@app.route('/delete/<int:id>')
def delete(id: int) -> Response:
    """Delete a todo item."""
    todo = Todo.get_by_id(id)
    if todo:
        todo.delete()
    return redirect(url_for('index'))

# Add error handlers
@app.errorhandler(403)
def forbidden_error(error):
    return render_template('error.html', error="Access Forbidden"), 403

@app.errorhandler(404)
def not_found_error(error):
    return render_template('error.html', error="Page Not Found"), 404

@app.errorhandler(500)
def internal_error(error):
    return render_template('error.html', error="Internal Server Error"), 500

# Global flag for DB availability
db_available = False

def check_db() -> bool:
    """Check database connectivity."""
    global db_available
    try:
        with app.app_context():
            db.session.execute(text('SELECT 1'))
            db_available = True
            return True
    except OperationalError as e:
        logger.error(f"Database connection failed: {e}")
        db_available = False
        return False

# Health check endpoints
@app.route('/health/live')
def liveness():
    """Kubernetes liveness probe."""
    return {'status': 'ok'}, 200

@app.route('/health/ready')
def readiness():
    """Kubernetes readiness probe."""
    if check_db():
        return {'status': 'ok'}, 200
    return {'status': 'unavailable'}, 503

if __name__ == '__main__':
    env = os.getenv('FLASK_ENV')
    if env == 'development':
        # Development server with debug and reloading
        app.run(host='0.0.0.0', port=8080, debug=True)
    elif env == 'production':
        serve(app, host='0.0.0.0', port=8080, threads=4)
    else:
        raise ValueError(f"Invalid FLASK_ENV value: {env}. Must be 'development' or 'production'")
