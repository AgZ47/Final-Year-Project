# To Do

## Phase 1: The "Pipeline"

- <ins>**_Goal:_**</ins> Get data from Watch -> Phone -> Server -> DB.\
- <ins>**_Backend:_**</ins> Setup FastAPI and PostgreSQL. Create the /data/sync endpoint.\
- <ins>**_Watch:_**</ins> Build the Kotlin service to read Heart Rate and send it to the phone.\
- <ins>**_App:_**</ins> Build a basic Flutter app that just displays the raw number from the server.\

## Phase 2: The "Rules Engine"

- <ins>**_Goal:_**</ins> Make the backend "smart" (Logic, not AI yet).\
- <ins>**_Backend:_**</ins> Implement the Rules Engine. If HR > 100, create an "Alert" object in the DB.\
- <ins>**_App:_**</ins> Add Push Notifications. When an Alert is created, the phone should buzz.\

## Phase 3: The "Therapist Export"

- <ins>**_Goal:_**</ins> PDF Generation.\
- <ins>**_Backend:_**</ins> Use matplotlib to generate a graph image of the user's HR. Use ReportLab to place that image in a PDF.\
- <ins>**_Backend:_**</ins> Connect the /report/email endpoint to a mail server (like SendGrid or Gmail SMTP).\

## Phase 4: The "AI Brain"

- <ins>**_Goal:_**</ins> Add the RAG and LLM.\
- <ins>**_Backend:_**</ins> When a journal comes in, vectorise it (using an embedding API) and store it in ChromaDB.\
- <ins>**_Backend:_**</ins> Update the Daily Plan generator to query ChromaDB for context ("What did the user do last time they were stressed?") before asking the LLM for advice.\

# How to section:

## How to Initialize git repo on device:

1. create new folder
2. open cmd in the folder by right clicking while inside the folder and selecting "open in terminal"
3. run this code in terminal:

```
git clone https://github.com/AgZ47/Final-Year-Project.git
```

## How to run backend:

1. open terminal in the "Backend" folder
2. run this commands in terminal to install all package dependencies:

```
npm install
```

3. run this command to run the backend program:

```
node index.js
```

## How to push to github:

1. open terminal in the root directory of the project which will be named "Final-Year-Project"
2. run these commands replacing "commit message" with your commit message eg."updated backend routes"

```
git add .
git commit -m "commit message"
git push -u  origin main
```

# How to run frontend:

1. open terminal in Frontend/health_app
2. run this command directly or open android emulator using ctrl+shift+p and then running this command:

```
flutter run
```
