#!/bin/bash
set -e

echo "Restoring database from backup..."
/opt/mssql-tools/bin/sqlcmd -S localhost -U sa -P "P@ssw0rd123" -Q "
RESTORE DATABASE [TestDb]
FROM DISK = N'/var/opt/mssql/backup/TestDb_10172025.bak'
WITH MOVE 'TestDb_10172025' TO '/var/opt/mssql/data/TestDb_10172025.mdf',
MOVE 'TestDb_10172025_log' TO '/var/opt/mssql/data/TestDb_10172025_log.ldf',
REPLACE;
"
echo "Restore completed."
