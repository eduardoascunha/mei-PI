CREATE OR REPLACE FUNCTION bmsql_proc_order_status(
    IN in_w_id integer,
    IN in_d_id integer,
    IN in_c_id integer,
    IN in_c_last varchar(16),
    OUT out_c_id integer,
    OUT out_c_first varchar(16),
    OUT out_c_middle char(2),
    OUT out_c_balance decimal(12,2),
    OUT out_o_id integer,
    OUT out_o_entry_d timestamp,
    OUT out_o_carrier_id integer,
    OUT out_ol_supply_w_id integer[],
    OUT out_ol_i_id integer[],
    OUT out_ol_quantity integer[],
    OUT out_ol_amount decimal(12,2)[],
    OUT out_ol_delivery_d timestamp[]
) AS
$$
DECLARE
    var_c_row record;
    var_o_row record;
    var_ol_rows record;
    var_n integer;
BEGIN
    -- If C_Last is given instead of C_ID (60%), determine the C_ID.
    IF in_c_last IS NOT NULL THEN
        out_c_id = bmsql_cid_from_clast(in_w_id, in_d_id, in_c_last);
    END IF;

    -- Select the CUSTOMER.
    SELECT INTO var_c_row
        c_id, c_first, c_middle, c_balance
        FROM bmsql_customer
        WHERE c_w_id = in_w_id AND c_d_id = in_d_id AND c_id = out_c_id;
    out_c_id = var_c_row.c_id;
    out_c_first = var_c_row.c_first;
    out_c_middle = var_c_row.c_middle;
    out_c_balance = var_c_row.c_balance;

    -- Select the ORDER.
    SELECT INTO var_o_row
        o_id, o_entry_d, o_carrier_id
        FROM bmsql_oorder
        WHERE o_w_id = in_w_id AND o_d_id = in_d_id AND o_c_id = out_c_id
        ORDER BY o_id DESC LIMIT 1;
    out_o_id = var_o_row.o_id;
    out_o_entry_d = var_o_row.o_entry_d;
    out_o_carrier_id = var_o_row.o_carrier_id;

    -- Select the ORDER-LINEs.
    out_ol_supply_w_id := ARRAY[]::integer[];
    out_ol_i_id := ARRAY[]::integer[];
    out_ol_quantity := ARRAY[]::integer[];
    out_ol_amount := ARRAY[]::decimal(12,2)[];
    out_ol_delivery_d := ARRAY[]::timestamp[];
    var_n := 0;
    FOR var_ol_rows IN
        SELECT ol_supply_w_id, ol_i_id, ol_quantity, ol_amount, ol_delivery_d
        FROM bmsql_order_line
        WHERE ol_w_id = in_w_id AND ol_d_id = in_d_id AND ol_o_id = out_o_id
    LOOP
        out_ol_supply_w_id := array_append(out_ol_supply_w_id, var_ol_rows.ol_supply_w_id);
        out_ol_i_id := array_append(out_ol_i_id, var_ol_rows.ol_i_id);
        out_ol_quantity := array_append(out_ol_quantity, var_ol_rows.ol_quantity);
        out_ol_amount := array_append(out_ol_amount, var_ol_rows.ol_amount);
        out_ol_delivery_d := array_append(out_ol_delivery_d, var_ol_rows.ol_delivery_d);
        var_n := var_n + 1;
    END LOOP;

    -- Pad the arrays to 15 elements if necessary.
    WHILE var_n < 15 LOOP
        out_ol_supply_w_id := array_append(out_ol_supply_w_id, 0);
        out_ol_i_id := array_append(out_ol_i_id, 0);
        out_ol_quantity := array_append(out_ol_quantity, 0);
        out_ol_amount := array_append(out_ol_amount, 0.0);
        out_ol_delivery_d := array_append(out_ol_delivery_d, NULL);
        var_n := var_n + 1;
    END LOOP;
END;
$$
LANGUAGE plpgsql;