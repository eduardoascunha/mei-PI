CREATE OR REPLACE FUNCTION bmsql_proc_order_status(
    IN in_w_id integer,
    IN in_d_id integer,
    INOUT in_c_id integer,
    IN in_c_last varchar(16),
    OUT out_c_first varchar(16),
    OUT out_c_middle char(2),
    OUT out_c_balance decimal(12, 2),
    OUT out_o_id integer,
    OUT out_o_entry_d timestamp,
    OUT out_o_carrier_id integer,
    OUT out_ol_supply_w_id integer[],
    OUT out_ol_i_id integer[],
    OUT out_ol_quantity integer[],
    OUT out_ol_amount decimal(12, 2)[],
    OUT out_ol_delivery_d timestamp[]
) AS
$$
DECLARE
    var_c_row record;
    var_o_row record;
    var_ol_row record;
    var_namecnt integer;
    var_i integer;
BEGIN
    -- If C_LAST is given instead of C_ID (60%), determine the C_ID.
    IF in_c_last IS NOT NULL THEN
        SELECT count(*) INTO var_namecnt
          FROM bmsql_customer
         WHERE c_w_id = in_w_id AND c_d_id = in_d_id
           AND c_last = in_c_last;
        SELECT c_id, c_first, c_middle, c_balance
          INTO in_c_id, out_c_first, out_c_middle, out_c_balance
          FROM bmsql_customer
         WHERE c_w_id = in_w_id AND c_d_id = in_d_id
           AND c_last = in_c_last
         ORDER BY c_first
         LIMIT 1 OFFSET (var_namecnt - 1) / 2;
    ELSE
        SELECT c_first, c_middle, c_balance
          INTO out_c_first, out_c_middle, out_c_balance
          FROM bmsql_customer
         WHERE c_w_id = in_w_id AND c_d_id = in_d_id
           AND c_id = in_c_id;
    END IF;

    -- Get the latest order.
    SELECT o_id, o_entry_d, o_carrier_id
      INTO out_o_id, out_o_entry_d, out_o_carrier_id
      FROM bmsql_oorder
     WHERE o_w_id = in_w_id AND o_d_id = in_d_id
       AND o_c_id = in_c_id
     ORDER BY o_id DESC
     LIMIT 1;

    -- Get the order lines.
    var_i := 0;
    FOR var_ol_row IN
        SELECT ol_supply_w_id, ol_i_id, ol_quantity,
               ol_amount, ol_delivery_d
          FROM bmsql_order_line
         WHERE ol_w_id = in_w_id AND ol_d_id = in_d_id
           AND ol_o_id = out_o_id
         ORDER BY ol_number
    LOOP
        var_i := var_i + 1;
        out_ol_supply_w_id[var_i] := var_ol_row.ol_supply_w_id;
        out_ol_i_id[var_i] := var_ol_row.ol_i_id;
        out_ol_quantity[var_i] := var_ol_row.ol_quantity;
        out_ol_amount[var_i] := var_ol_row.ol_amount;
        out_ol_delivery_d[var_i] := var_ol_row.ol_delivery_d;
    END LOOP;
    IF var_i < 15 THEN
        FOR var_i IN var_i + 1 .. 15 LOOP
            out_ol_supply_w_id[var_i] := 0;
            out_ol_i_id[var_i] := 0;
            out_ol_quantity[var_i] := 0;
            out_ol_amount[var_i] := 0.0;
            out_ol_delivery_d[var_i] := NULL;
        END LOOP;
    END IF;
END;
$$
LANGUAGE plpgsql;