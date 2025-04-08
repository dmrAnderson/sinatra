# Instructions for Running the Sinatra Application with PostgreSQL and pgAdmin

This document explains how to use the provided `docker-compose.yml` to run a Sinatra app with PostgreSQL and pgAdmin.

## What We Have

Defines `db` (PostgreSQL), `app` (Sinatra), and `pgadmin` services using Docker. Includes persistent volumes for database and pgAdmin data.

## How to Use It

1.  **Save `docker-compose.yml`:** Place the file in your Sinatra project root.
2.  **Create `Dockerfile`:** In the same directory, create a Dockerfile to build your Sinatra app image. Ensure it sets up the environment and runs the app on port `4567`.
3.  **Start Services:** Run `docker-compose up -d` in the terminal.
4.  **Access App:** Open `http://localhost:4567` in your browser.
5.  **Access pgAdmin:** Open `http://localhost:5050`, log in with `admin@admin.com` / `admin` (change password after login). Connect to the database in pgAdmin using host `db`, port `5432`, user `postgres`, password `postgres`, and database `sinatra_app`.
6.  **Stop Services:** Run `docker-compose down`.
7.  **Restart Services:** Run `docker-compose up -d`.

## Running Tests

Execute your Sinatra tests using:

```bash
docker-compose run --rm app bundle exec ruby -Itest app_test.rb
```
