<ins>**Phase 1: The "Pipeline"**</ins>

**_Goal:_** Get data from Watch -> Phone -> Server -> DB.
**_Backend:_** Setup FastAPI and PostgreSQL. Create the /data/sync endpoint.

**_Watch:_** Build the Kotlin service to read Heart Rate and send it to the phone.

**_App:_** Build a basic Flutter app that just displays the raw number from the server.
<ins>**Phase 2: The "Rules Engine"**</ins>

**_Goal:_** Make the backend "smart" (Logic, not AI yet).
**_Backend:_** Implement the Rules Engine. If HR > 100, create an "Alert" object in the DB.
**_App:_** Add Push Notifications. When an Alert is created, the phone should buzz.
<ins>**Phase 3: The "Therapist Export"**</ins>

**_Goal:_** PDF Generation.
**_Backend:_** Use matplotlib to generate a graph image of the user's HR. Use ReportLab to place that image in a PDF.
**_Backend:_** Connect the /report/email endpoint to a mail server (like SendGrid or Gmail SMTP).
<ins>**Phase 4: The "AI Brain"**</ins>

**_Goal:_** Add the RAG and LLM.

**_Backend:_** When a journal comes in, vectorise it (using an embedding API) and store it in ChromaDB.

**_Backend:_** Update the Daily Plan generator to query ChromaDB for context ("What did the user do last time they were stressed?") before asking the LLM for advice.
