DO $$
DECLARE
   row_count integer := 1;
   batch_size  integer := 100000; -- HOW MANY ITEMS WILL BE UPDATED AT TIME
   iterator  integer := batch_size;
   affected integer;
BEGIN
  DROP TABLE IF EXISTS transactions_temp;

  -- CREATES TEMP TABLE TO STORE DATA TO BE UPDATED
  CREATE TEMP TABLE transactions_temp(hash bytea, block_number integer, row_number integer);

  INSERT INTO transactions_temp
  SELECT
    t.hash,
    t.block_number,
    ROW_NUMBER () OVER ()
  FROM token_transfers AS tt
  INNER JOIN transactions AS t ON t.hash = tt.transaction_hash;

  row_count := (SELECT count(*) FROM transactions_temp);

  RAISE NOTICE '% items to be updated', row_count;

  -- ITERATES THROUGH THE ITEMS UNTIL THE TEMP TABLE IS EMPTY
  WHILE row_count > 0 LOOP
    -- UPDATES TOKEN TRANSFERS AND RETURNS THE TRANSACTION HASH TO BE DELETED
    WITH updated_token_transfers AS (
      UPDATE token_transfers
      SET
        block_number = transactions_temp.block_number
      FROM transactions_temp
      WHERE token_transfers.transaction_hash = transactions_temp.hash
      AND transactions_temp.row_number <= iterator
      RETURNING transactions_temp.hash
    )
    -- DELETES THE ITENS UPDATED FROM THE TEMP TABLE
    DELETE FROM transactions_temp tt
    USING  updated_token_transfers uit
    WHERE  tt.hash = uit.hash;

    GET DIAGNOSTICS affected = ROW_COUNT;
    RAISE NOTICE '-> % token transfers updated!', affected;

    CHECKPOINT; -- COMMITS THE BATCH UPDATES

    -- UPDATES THE COUNTER SO IT DOESN'T TURN INTO AN INFINITE LOOP
    row_count := (SELECT count(*) FROM transactions_temp);
    iterator := iterator + batch_size;

    RAISE NOTICE '-> % counter', row_count;
    RAISE NOTICE '-> % next batch', iterator;
  END LOOP;
END $$;
