CREATE OR REPLACE FUNCTION bmsql_new_order_txn(
in_w_id integer,
in_d_id integer,
in_c_id integer,
in_ol_supply_w_id integer[],
in_ol_i_id integer[],
in_ol_quantity integer[]
)
RETURNS TABLE(
out_w_tax decimal(4,4),
out_d_tax decimal(4,4),
out_o_id integer,
out_o_entry_d timestamp,
out_ol_cnt integer,
out_ol_amount decimal(12,2)[],
out_total_amount decimal(12,2),
out_c_last varchar,
out_c_credit char(2),
out_c_discount decimal(4,4),
out_i_name varchar(24)[],
out_i_price decimal(5,2)[],
out_s_quantity integer[],
out_brand_generic char[]
) AS
$$
DECLARE
v_ol_cnt integer;
v_w_tax decimal(4,4);
v_d_tax decimal(4,4);
v_o_id integer;
v_o_entry_d timestamp := clock_timestamp();
v_c_discount decimal(4,4);
v_c_last varchar(16);
v_c_credit char(2);
v_next_o_id integer;
v_o_all_local integer;
v_sum_ol_amount numeric(18,2) := 0;
v_idx integer;
v_i_price decimal(5,2);
v_i_name varchar(24);
v_i_data varchar(50);
v_s_quantity integer;
v_s_ytd integer;
v_s_order_cnt integer;
v_s_remote_cnt integer;
v_s_data varchar(50);
v_s_dist_info char(24);
v_supply_w_id integer;
v_i_id integer;
v_ol_qty integer;
v_brand char(1);
v_invalid_last_item boolean := false;
v_all_local boolean := true;
BEGIN
-- Validate arrays
IF in_ol_i_id IS NULL OR in_ol_supply_w_id IS NULL OR in_ol_quantity IS NULL THEN
RAISE EXCEPTION 'Item arrays must not be null';
END IF;


v_ol_cnt := array_length(in_ol_i_id,1);
IF v_ol_cnt IS NULL OR v_ol_cnt <> array_length(in_ol_supply_w_id,1) OR v_ol_cnt <> array_length(in_ol_quantity,1) THEN
    RAISE EXCEPTION 'Array inputs must be non-null and of equal length';
END IF;

-- Initialize outputs arrays empty
out_ol_amount := ARRAY[]::decimal(12,2)[];
out_i_name := ARRAY[]::varchar(24)[];
out_i_price := ARRAY[]::decimal(5,2)[];
out_s_quantity := ARRAY[]::integer[];
out_brand_generic := ARRAY[]::char[];

-- 1) Get warehouse tax
SELECT bmsql_warehouse.w_tax
INTO v_w_tax
FROM bmsql_warehouse
WHERE bmsql_warehouse.w_id = in_w_id;

IF NOT FOUND THEN
    RAISE EXCEPTION 'Warehouse % not found', in_w_id;
END IF;

-- 2) Get district tax and next_o_id, lock district row for update
SELECT bmsql_district.d_next_o_id, bmsql_district.d_tax
INTO v_next_o_id, v_d_tax
FROM bmsql_district
WHERE bmsql_district.d_w_id = in_w_id
  AND bmsql_district.d_id = in_d_id
FOR UPDATE;

IF NOT FOUND THEN
    RAISE EXCEPTION 'District %/% not found', in_w_id, in_d_id;
END IF;

-- compute order id and increment district next_o_id
v_o_id := v_next_o_id;
UPDATE bmsql_district
SET d_next_o_id = v_next_o_id + 1
WHERE bmsql_district.d_w_id = in_w_id
  AND bmsql_district.d_id = in_d_id;

-- 3) Get customer discount, last, credit
SELECT bmsql_customer.c_discount, bmsql_customer.c_last, bmsql_customer.c_credit
INTO v_c_discount, v_c_last, v_c_credit
FROM bmsql_customer
WHERE bmsql_customer.c_w_id = in_w_id
  AND bmsql_customer.c_d_id = in_d_id
  AND bmsql_customer.c_id = in_c_id;

IF NOT FOUND THEN
    RAISE EXCEPTION 'Customer %/%/% not found', in_w_id, in_d_id, in_c_id;
END IF;

-- Determine if all local
FOR v_idx IN 1..v_ol_cnt LOOP
    IF in_ol_supply_w_id[v_idx] IS DISTINCT FROM in_w_id THEN
        v_all_local := false;
        EXIT;
    END IF;
END LOOP;
v_o_all_local := CASE WHEN v_all_local THEN 1 ELSE 0 END;

-- 4) perform the main order insertion and item processing inside a subtransaction
BEGIN
    -- Insert order header into bmsql_oorder
    INSERT INTO bmsql_oorder (
        o_w_id, o_d_id, o_id, o_c_id, o_carrier_id, o_ol_cnt, o_all_local, o_entry_d
    ) VALUES (
        in_w_id, in_d_id, v_o_id, in_c_id, NULL, v_ol_cnt, v_o_all_local, v_o_entry_d
    );

    -- Insert into new order table
    INSERT INTO bmsql_new_order (no_w_id, no_d_id, no_o_id)
    VALUES (in_w_id, in_d_id, v_o_id);

    -- Process each order-line
    FOR v_idx IN 1..v_ol_cnt LOOP
        v_i_id := in_ol_i_id[v_idx];
        v_supply_w_id := in_ol_supply_w_id[v_idx];
        v_ol_qty := in_ol_quantity[v_idx];

        -- Read item; if not found and it's the last item, signal the special invalid-last-item error
        SELECT bmsql_item.i_price, bmsql_item.i_name, bmsql_item.i_data
        INTO v_i_price, v_i_name, v_i_data
        FROM bmsql_item
        WHERE bmsql_item.i_id = v_i_id;

        IF NOT FOUND THEN
            IF v_idx = v_ol_cnt THEN
                -- signal special condition to cause subtransaction rollback but allow outer function to return O_ID info
                RAISE EXCEPTION 'Item number is not valid';
            ELSE
                RAISE EXCEPTION 'Item % not found (position %)', v_i_id, v_idx;
            END IF;
        END IF;

        -- Read stock row for this item and supplier warehouse, lock it
        SELECT bmsql_stock.s_quantity,
               bmsql_stock.s_ytd,
               bmsql_stock.s_order_cnt,
               bmsql_stock.s_remote_cnt,
               bmsql_stock.s_data,
               CASE WHEN in_d_id = 1 THEN bmsql_stock.s_dist_01
                    WHEN in_d_id = 2 THEN bmsql_stock.s_dist_02
                    WHEN in_d_id = 3 THEN bmsql_stock.s_dist_03
                    WHEN in_d_id = 4 THEN bmsql_stock.s_dist_04
                    WHEN in_d_id = 5 THEN bmsql_stock.s_dist_05
                    WHEN in_d_id = 6 THEN bmsql_stock.s_dist_06
                    WHEN in_d_id = 7 THEN bmsql_stock.s_dist_07
                    WHEN in_d_id = 8 THEN bmsql_stock.s_dist_08
                    WHEN in_d_id = 9 THEN bmsql_stock.s_dist_09
                    WHEN in_d_id = 10 THEN bmsql_stock.s_dist_10
                    ELSE NULL END
        INTO v_s_quantity, v_s_ytd, v_s_order_cnt, v_s_remote_cnt, v_s_data, v_s_dist_info
        FROM bmsql_stock
        WHERE bmsql_stock.s_w_id = v_supply_w_id
          AND bmsql_stock.s_i_id = v_i_id
        FOR UPDATE;

        IF NOT FOUND THEN
            -- If stock row doesn't exist, treat as error (shouldn't happen for valid item and warehouse)
            RAISE EXCEPTION 'Stock %/% not found', v_supply_w_id, v_i_id;
        END IF;

        -- Save S_QUANTITY before update into output array
        out_s_quantity := out_s_quantity || v_s_quantity;

        -- Update stock quantity per rules
        IF v_s_quantity > (v_ol_qty + 10) THEN
            v_s_quantity := v_s_quantity - v_ol_qty;
        ELSE
            v_s_quantity := v_s_quantity - v_ol_qty + 91;
        END IF;

        v_s_ytd := COALESCE(v_s_ytd,0) + v_ol_qty;
        v_s_order_cnt := COALESCE(v_s_order_cnt,0) + 1;
        IF v_supply_w_id <> in_w_id THEN
            v_s_remote_cnt := COALESCE(v_s_remote_cnt,0) + 1;
        END IF;

        -- Apply stock updates
        UPDATE bmsql_stock
        SET s_quantity = v_s_quantity,
            s_ytd = v_s_ytd,
            s_order_cnt = v_s_order_cnt,
            s_remote_cnt = v_s_remote_cnt,
            s_data = v_s_data
        WHERE bmsql_stock.s_w_id = v_supply_w_id
          AND bmsql_stock.s_i_id = v_i_id;

        -- Compute OL_AMOUNT
        out_ol_amount := out_ol_amount || (v_ol_qty * v_i_price);
        v_sum_ol_amount := v_sum_ol_amount + (v_ol_qty * v_i_price);

        -- Determine brand/generic: both I_DATA and S_DATA contain 'ORIGINAL' -> 'B' else 'G'
        IF v_i_data IS NOT NULL AND v_s_data IS NOT NULL
           AND position('ORIGINAL' in v_i_data) > 0
           AND position('ORIGINAL' in v_s_data) > 0 THEN
            v_brand := 'B';
        ELSE
            v_brand := 'G';
        END IF;
        out_brand_generic := out_brand_generic || v_brand;

        -- Collect item name and price arrays
        out_i_name := out_i_name || v_i_name;
        out_i_price := out_i_price || v_i_price;

        -- Insert into order_line
        INSERT INTO bmsql_order_line (
            ol_w_id, ol_d_id, ol_o_id, ol_number, ol_i_id, ol_delivery_d,
            ol_amount, ol_supply_w_id, ol_quantity, ol_dist_info
        ) VALUES (
            in_w_id, in_d_id, v_o_id, v_idx, v_i_id, NULL,
            (v_ol_qty * v_i_price), v_supply_w_id, v_ol_qty, v_s_dist_info
        );
    END LOOP; -- per-item processing

EXCEPTION
    WHEN OTHERS THEN
        -- If the exception message indicates invalid last item, mark to return special rollback result.
        IF SQLERRM LIKE 'Item number is not valid%' THEN
            v_invalid_last_item := true;
            -- Subtransaction rollback happens automatically at the end of this block; re-raise to allow subtransaction to rollback
            -- Use RAISE to abort this subtransaction; the outer block will continue after the inner block's EXCEPTION handling
            -- But to allow us to continue after rollback we simply EXIT the inner block by returning control to outer block (we are in EXCEPTION block)
            -- Note: Do nothing here; leaving the EXCEPTION block will cause the subtransaction to be rolled back.
        ELSE
            -- Re-raise other unexpected exceptions
            RAISE;
        END IF;
END; -- end subtransaction block

-- If there was an invalid last item, the inner subtransaction has been rolled back.
IF v_invalid_last_item THEN
    -- Return minimal outputs per spec: return O_ID (the order number that would have been used), customer info and a minimal set of other fields.
    out_w_tax := v_w_tax;
    out_d_tax := v_d_tax;
    out_o_id := v_o_id;
    out_o_entry_d := v_o_entry_d;
    out_ol_cnt := v_ol_cnt;
    out_ol_amount := ARRAY[]::decimal(12,2)[];
    out_total_amount := 0;
    out_c_last := v_c_last;
    out_c_credit := v_c_credit;
    out_c_discount := v_c_discount;
    out_i_name := ARRAY[]::varchar(24)[];
    out_i_price := ARRAY[]::decimal(5,2)[];
    out_s_quantity := ARRAY[]::integer[];
    out_brand_generic := ARRAY[]::char[];
    RETURN NEXT;
    RETURN;
END IF;

-- 5) Compute total amount
out_total_amount := (v_sum_ol_amount * (1 - v_c_discount) * (1 + v_w_tax + v_d_tax));

-- Fill scalar outputs
out_w_tax := v_w_tax;
out_d_tax := v_d_tax;
out_o_id := v_o_id;
out_o_entry_d := v_o_entry_d;
out_ol_cnt := v_ol_cnt;
out_c_last := v_c_last;
out_c_credit := v_c_credit;
out_c_discount := v_c_discount;

RETURN NEXT;


END;
$$
LANGUAGE plpgsql;
