# Authoring Web Client Onboarding

This document describes how to build and run the Soundscape Authoring web app.

## Overview

Soundscape Authoring is a web app which allows users to create routed activities for use with the Soundscape iOS app.

## Tech Stack

- [Azure](https://azure.microsoft.com/)
  - Azure Database for PostgreSQL server
  - Storage account
  - Azure Maps
  - App Service
  - B2C Tenant for authentication (using Microsoft account login)
- Backend
  - Python
  - Django
- Frontend
  - JavaScript
  - React
  - Bootstrap
- IDE
  - VSCode
  - Azure Account + App Service VSCode extensions

## Azure Setup

In your Azure account:

1. Create a `Resource Group`.
2. Create a `Storage Account` (for app content, images, GPX files, etc).
   1. Create a blob container named "authoring" with Blob public access level.
3. Create an Azure Database for `PostgreSQL Server` (for Django content).
   1. Go to "Connection Security" and in "Allow access to Azure services" select "Yes".
   2. Create a Database named "authoring". You can use Terminal:
      1. Go to "Connection Security" and add your IP.
      2. Go to "Connection Strings" and copy the `psql` string. Default DB is `postgres`.
      3. `psql "host=host port=port dbname=dbname user=user password=password sslmode=require"`
      4. `CREATE DATABASE authoring;`
      5. `\q`
4. Create a `B2C Tenant`.
   1. Create `App registration` application.
      1. For Platform configuration, add Web and for the redirect URIs use: `<app-url>/.auth/login/aad/callback`.
      2. Put a checkmark next to `ID tokens`.
      3. Save the `Application (client) ID` from the Overview page.
   2. Create a User Flow with the claims country, display name and object ID.
5. Create an `App Service` with B2 App Service Plan.
   1. Go to `Configuration` and add environment variables (see `.env.example` file).
   2. Go to `Authentication` and add the `Microsoft` identity provider. Use the saved client ID from the previous step.

## Authentication

- In production, we use `Azure B2C` to authenticate the user. After authentication, we load the `URL/.auth/me` resource, which contains a JSON file with access tokens and the needed user ID (`objectidentifier`).
- In development, we don't have a way to use the B2C authentication flow. Use the following guidance:
  - Open the existing production webpage followed by `/.auth/me`.
  - Download the JSON and store it in `/backend/.auth/me.json`.
  - At debug, the project will load this file and it will be used as the credentials.
  - Important! Make sure to not commit this file to `Git`.

## Development Flow

The project contains two folders, `backend` and `frontend`.

- **Backend**
  - To run the project locally, open the `backend` folder in VSCode and run the project (See [Backend](#backend) for more info).
  - This will make the backend webpage available at the following addresses:
    - <http://127.0.0.1:8000/> serves the frontend React SPA webpage.
    - <http://127.0.0.1:8000/api/v1/> serves the Django REST API webpage.
- **Frontend**
  - Open the `frontend` folder as a separate VSCode window and run the project (See [Frontend](#frontend) for more info).
  - Running:
    - Run the command `npm run start` (or press the run button in the NPM scripts section).
    - Run via VSCode (F5).
    - Access the frontend webpage at <http://10.0.0.155:3000/>.
  - Building:
    - When building the frontend project (as opposed to running) it injects the compiled React SPA webpage files into the folder `/backend/frontend/serve`. These are the files that will be served in production and also when viewing <http://127.0.0.1:8000/>.

## Backend

1. In the `/backend` folder, if there is no virtual environment (`.venv`), create one and select it as the default Python interpreter in VSCode. Run `python3 -m venv .venv`.
2. If the Python packages are not installed, run `pip install -r requirements.txt`.
3. Run:
   1. python manage.py makemigrations
   2. python manage.py makemigrations api
   3. python manage.py migrate
4. In the folder `/backend/.env`:
   1. Create the files `local.env`, `development.env` and `production.env`.
   2. Fill in the needed properties as shown in the `example.env` file. You can use the values in the `Configuration` section of the Azure App Service resource.
5. Add the auth file as described in the [Authentication](#authentication) section.
6. Before running, make sure you are running the needed configuration - in the file `/backend/.vscode/lunch.json`, make sure the `envFile` property points to the environment file you are looking to run.
7. Run via VSCode (F5).

Note that when running in a `local` environment, data is stored and retrieved from a local `SQLite` file. For `development` and `production`, the database is a PostgreSQL server.

## Database migration (when adding/removing/editing model data)

1. Make change to the model objects in the `models.py` file (and other files such as `serializers.py` if needed).
2. Make sure you are running the needed configuration - in the file `/backend/.vscode/lunch.json`, make sure the `envFile` property points to the environment file you are looking to run in.
3. Run the following lunch schemes:
   1. `Django Make Migrations`
   2. `Django Migrate`

**Important!** Double check before doing this, as this can migrate a production database if the environment property is not set properly in the lunch configurations.

## Frontend

1. In the `/frontend` folder, if the NPM packages are not installed, run `npm install`.
2. Make sure to add the `authentication` file to the backend (See the [Authentication](#authentication) section).
3. Run the command `npm run start` (or press the run button in the NPM scripts section).
   1. Run via VSCode (F5).
   2. Access the frontend webpage at <http://10.0.0.155:3000/>.

## Allow-list

There is a simple allowlist that only allows specific emails to access the webpage.
This list is managed in the backend app, under the data model `UserPermissions`.
In order to view and add emails to the allowlist, do the following:

1. In Azure, go to "Connection Security" and add your IP. Add Rule, Start IP and End IP should be the same IPv4 as yours.
2. Using a PostgreSQL command-line or GUI, connect to the Azure DB or open the SQLite file if running locally (you can use Azure Data Studio with the [PostgreSQL](https://docs.microsoft.com/en-us/sql/azure-data-studio/extensions/postgres-extension?view=sql-server-ver16) extension).
3. Select the table `public.api_userpermissions`.
4. Add a row with `user_email` and input `true` in the `allow_app` value.

## Deploy to Azure Web Apps

1. You should only deploy the backend folder, as it contains the compiled React frontend files in the `/backend/frontend/serve` folder.
2. **Important!** Make sure to build the frontend (React) application before uploading.
3. Select the Azure extension in VSCode, select App Service, press the "Deploy to Web App" button and select the App Service destination.
4. When complete, wait a couple of minutes and access the webpage to see if the changes are live.

## [Exporting from the Authoring Web App](./exporting.md)
