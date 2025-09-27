FROM postgres:16-alpine

ENV POSTGRES_PASSWORD=mysecretpassword

COPY init.sql /docker-entrypoint-initdb.d/
