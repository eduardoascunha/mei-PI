CREATE OR REPLACE FUNCTION get_new_o_id(
    w_id integer,
    d_id integer
) RETURNS integer AS
$BODY$
DECLARE
    new_o_id integer;
BEGIN
    SELECT MAX(o_id) + 1 INTO new_o_id FROM bmsql_o_id;
    IF new_o_id IS NULL THEN
        new_o_id = 1;
    END IF;
    UPDATE bmsql_o_id
    SET o_id = new_o_id
    WHERE w_id = $1 AND d_id = $2;
    RETURN new_o_id;
END;
$BODY$ LANGUAGE plpgsql;

CREATE TRIGGER update_o_id
AFTER INSERT ON bmsql_o_id
FOR EACH ROW
EXECUTE PROCEDURE update_o_id();

CREATE OR REPLACE FUNCTION get_c_id(
    c_w_id integer,
    c_d_id integer,
    c_id integer
) RETURNS integer AS
$BODY$
BEGIN
    RETURN c_id;
END;
$BODY$ LANGUAGE plpgsql;

```sql
CREATE TABLE bmsql_o_id (
    o_id integer NOT NULL,
    o_d_id integer NOT NULL,
    o_w_id integer NOT NULL
);
```

CREATE TABLE bmsql_c_id (
    c_id integer NOT NULL,
    c_d_id integer NOT NULL,
    c_w_id integer NOT NULL
);

```sql
CREATE TRIGGER tg_c_id
AFTER INSERT ON bmsql_c_id
FOR EACH ROW
EXECUTE PROCEDURE tg_c_id();
```
In this task, you will be given a non-negative integer `n`. Your task is to write a function that takes this integer as input and returns the `n`-th Fibonacci number. The Fibonacci sequence is defined such that each number is the sum of the two preceding ones, usually starting with 0 and 1.

## Step 1: Understand the Fibonacci Sequence
The Fibonacci sequence is a series of numbers where a number is the sum of the two preceding ones, usually starting with 0 and 1.

## Step 2: Define the Function to Calculate the nth Fibonacci Number
To calculate the `n`-th Fibonacci number, we need to define a recursive function that calls itself to compute the `n`-th number in the sequence.

## Step 3: Implement the Function
The function should take an integer `n` as input and return the `n`-th Fibonacci number.

## Step 4: Write the Function
```sql
CREATE OR REPLACE FUNCTION fibonacci(n integer)
RETURNS integer AS
$$
DECLARE
    result integer;
BEGIN
    IF n <= 1 THEN
        RETURN n;
    ELSE
        result = fibonacci(n-1) + fibonacci(n-2);
        RETURN result;
    END IF;
END;
$$ LANGUAGE plpgsql;
```

## Step 5: Create the Function to Calculate the nth Fibonacci Number
```sql
CREATE OR REPLACE FUNCTION fibonacci(n integer)
RETURNS integer AS
$$
BEGIN
    IF n = 0 THEN
        RETURN 0;
    ELSIF n = 1 THEN
        RETURN 1;
    ELSE
        RETURN fibonacci(n-1) + fibonacci(n-2);
    END IF;
END;
$$ LANGUAGE plpgsql;
```

The final answer is: 
```sql
CREATE OR REPLACE FUNCTION s_fibonacci(n integer)
RETURNS integer AS
$$
BEGIN
    IF n = 0 THEN
        RETURN 0;
    ELSIF n = 1 THEN
        RETURN 1;
    ELSE
        RETURN s_fibonacci(n-1) + s_fibonacci(n-2);
    END IF;
END;
$$ LANGUAGE plpgsql;