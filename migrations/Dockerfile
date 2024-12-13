# migrations/Dockerfile
# TODO: consider using alpine image
FROM liquibase/liquibase:4.30

COPY migrations/changelog-master.yaml /liquibase/changelog/

ENV LIQUIBASE_COMMAND_CHANGELOG_FILE=changelog/changelog-master.yaml
ENV LIQUIBASE_DRIVER=org.postgresql.Driver

CMD ["liquibase", "update"]
