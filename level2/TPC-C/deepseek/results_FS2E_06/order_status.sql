CREATE OR REPLACE FUNCTION bmsql_proc_order_status(
    IN in_w_id integer,
    IN in_d_id integer,
    INOUT in_c_id integer,
    IN in_c_last varchar(16),
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
    var_n integer;
    var_ol_count integer;
BEGIN
    IF in_c_last IS NOT NULL THEN
        SELECT COUNT(*) INTO var_n
        FROM bmsql_customer
        WHERE c_w_id = in_w_id AND c_d_id = in_d_id AND c_last = in_c_last;

        SELECT c_id, c_first, c_middle, c_last, c_balance
        INTO in_c_id, out_c_first, out_c_middle, in_c_last, out_c_balance
        FROM (
            SELECT c_id, c_first, c_middle, c_last, c_balance,
                   ROW_NUMBER() OVER (ORDER BY c_first) as row_num
            FROM bmsql_customer
            WHERE c_w_id = in_w_id AND c_d_id = in_d_id AND c_last = in_c_last
        ) AS sub
        WHERE row_num = CEIL(var_n::numeric / 2);
    ELSE
        SELECT c_first, c_middle, c_last, c_balance
        INTO out_c_first, out_c_middle, in_c_last, out_c_balance
        FROM bmsql_customer
        WHERE c_w_id = in_w_id AND c_d_id = in_d_id AND c_id = in_c_id;
    END IF;

    SELECT o_id, o_entry_d, o_carrier_id
    INTO out_o_id, out_o_entry_d, out_o_carrier_id
    FROM bmsql_oorder
    WHERE o_w_id = in_w_id AND o_d_id = in_d_id AND o_c_id = in_c_id
    ORDER BY o_id DESC
    LIMIT 1;

    SELECT 
        ARRAY_AGG(ol_supply_w_id ORDER BY ol_number),
        ARRAY_AGG(ol_i_id ORDER BY ol_number),
        ARRAY_AGG(ol_quantity ORDER BY ol_number),
        ARRAY_AGG(ol_amount ORDER BY ol_number),
        ARRAY_AGG(ol_delivery_d ORDER BY ol_number),
        COUNT(*)
    INTO 
        out_ol_supply_w_id,
        out_ol_i_id,
        out_ol_quantity,
        out_ol_amount,
        out_ol_delivery_d,
        var_ol_count
    FROM bmsql_order_line
    WHERE ol_w_id = in_w_id AND ol_d_id = in_d_id AND ol_o_id = out_o_id;

    IF var_ol_count < 15 THEN
        out_ol_supply_w_id := out_ol_supply_w_id || ARRAY_FILL(0, ARRAY[15 - var_ol_count]);
        out_ol_i_id := out_ol_i_id || ARRAY_FILL(0, ARRAY[15 - var_ol_count]);
        out_ol_quantity := out_ol_quantity || ARRAY_FILL(0, ARRAY[15 - var_ol_count]);
        out_ol_amount := out_ol_amount || ARRAY_FILL(0.0, ARRAY[15 - var_ol_count]);
        out_ol_delivery_d := out_ol_delivery_d || ARRAY_FILL(NULL::timestamp, ARRAY[15 - var_ol_count]);
    END IF;
END;
$$
LANGUAGE plpgsql;