#!/bin/sh

USER=$1
PASS=$2
DATABASE=$3

EXEC="mysql --skip-column-names -u ${USER} -p${PASS} "

echo $EXEC
exit

(cat <<- _EOF_
SELECT DISTINCT
CONCAT('SELECT ',ndxcollist,' FROM ',
    db,'.',tb,' ORDER BY ',ndxcollist,';') SelectQueryToLoadCache
FROM (
    SELECT
    engine,table_schema db,table_name tb,index_name,
    GROUP_CONCAT(column_name ORDER BY seq_in_index) ndxcollist
    FROM (
        SELECT
        B.engine,A.table_schema,A.table_name,
        A.index_name,A.column_name,A.seq_in_index
        FROM
        information_schema.statistics A INNER JOIN
        (
            SELECT engine,table_schema,table_name
            FROM information_schema.tables
            WHERE TABLE_SCHEMA = '${DATABASE}'
        ) B USING (table_schema,table_name)
        WHERE
        B.table_schema NOT IN ('information_schema','mysql')
        AND A.index_type <> 'FULLTEXT'
        ORDER BY
        table_schema,table_name,index_name,seq_in_index
    ) A
    GROUP BY
    table_schema,table_name,index_name
) AA
ORDER BY
engine DESC,db,tb
;
_EOF_
) | $EXEC | while read line
do
    echo "$line" | $EXEC > /dev/null &
done

wait
