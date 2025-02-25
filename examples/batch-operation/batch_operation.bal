import ballerina/io;
import ballerinax/postgresql;
import ballerina/sql;

// The username , password and name of the PostgreSQL database
configurable string dbUsername = "postgres";
configurable string dbPassword = "postgres";
configurable string dbName = "postgres";
configurable int port = 5432;

public function main() returns error? {
    // Runs the prerequisite setup for the example.
    check beforeExample();

    // Initializes the PostgreSQL client.
    postgresql:Client dbClient = check new (username = dbUsername,
                password = dbPassword, database = dbName);

    // The records to be inserted.
    var insertRecords = [
        {firstName: "Peter", lastName: "Stuart", registrationID: 1,
                                    creditLimit: 5000.75, country: "USA"},
        {firstName: "Stephanie", lastName: "Mike", registrationID: 2,
                                    creditLimit: 8000.00, country: "USA"},
        {firstName: "Bill", lastName: "John", registrationID: 3,
                                    creditLimit: 3000.25, country: "USA"}
    ];

    // Creates a batch parameterized query.
    sql:ParameterizedQuery[] insertQueries =
        from var data in insertRecords
            select  `INSERT INTO Customers
                (firstName, lastName, registrationID, creditLimit, country)
                VALUES (${data.firstName}, ${data.lastName},
                ${data.registrationID}, ${data.creditLimit}, ${data.country})`;

    // Inserts the records with the auto-generated ID.
    sql:ExecutionResult[] result =
                            check dbClient->batchExecute(insertQueries);

    int[] generatedIds = [];
    foreach var summary in result {
        generatedIds.push(<int> summary.lastInsertId);
    }
    io:println("\nInsert success, generated IDs are: ", generatedIds, "\n");

    // Checks the data after the batch execution.
    stream<record{}, error?> resultStream =
        dbClient->query(`SELECT * FROM Customers`);

    io:println("Data in Customers table:");
    error? e = resultStream.forEach(function(record {} result) {
                 io:println(result.toString());
    });

    // Closes the PostgreSQL client.
    check dbClient.close();
}

// Initializes the database as a prerequisite to the example.
function beforeExample() returns sql:Error? {
    // Initializes the PostgreSQL client.
    postgresql:Client dbClient = check new (username = dbUsername,
                password = dbPassword, database = dbName);

    // Creates a table in the database.
    sql:ExecutionResult result = check dbClient->execute(`DROP TABLE IF EXISTS Customers`);
    result = check dbClient->execute(`CREATE TABLE Customers
            (customerId SERIAL, firstName VARCHAR(300), lastName  VARCHAR(300),
             registrationID INTEGER UNIQUE, creditLimit DOUBLE PRECISION,
             country  VARCHAR(300), PRIMARY KEY (customerId))`);

    // Closes the PostgreSQL client.
    check dbClient.close();
}
