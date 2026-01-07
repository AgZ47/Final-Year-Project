const { Client } = require("pg");

const dbclient = new Client({
  user: process.env.PGNUSER,
  password: process.env.PGNPASSWORD,
  host: process.env.PGNHOST,
  port: process.env.PGNPORT,
  database: process.env.PGNDATABASE,
  ssl: {
    rejectUnauthorized: false, // Required for Neon/AWS connections
  },
});

if (dbclient.connect()) {
  console.log("Database Connected Successfully");
}

module.exports = {
  dbclient,
};
