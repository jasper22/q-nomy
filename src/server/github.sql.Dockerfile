# Prepare SQL Server 2019
FROM postgres:13

ENV POSTGRES_USER user01
ENV POSTGRES_PASSWORD Password1

EXPOSE 5432

LABEL "qnomy"="sql"