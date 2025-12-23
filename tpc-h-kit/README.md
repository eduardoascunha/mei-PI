tpch-kit
========

TPC-H benchmark kit with some modifications/additions

Official TPC-H benchmark - [http://www.tpc.org/tpch](http://www.tpc.org/tpch)

## Setup

### Linux

Make sure the required development tools are installed:

Ubuntu:
```
sudo apt-get install git make gcc
```

Then run the following commands to clone the repo and build the tools:

```
git clone https://github.com/gregrahn/tpch-kit.git
cd tpch-kit/dbgen
make MACHINE=LINUX DATABASE=POSTGRESQL
```

### macOS

Make sure the required development tools are installed:

```
xcode-select --install
```

Then run the following commands to clone the repo and build the tools:

```
git clone https://github.com/gregrahn/tpch-kit.git
cd tpch-kit/dbgen
make MACHINE=MACOS DATABASE=POSTGRESQL
```

## Using the TPC-H tools

### Environment

To run it from scratch, you first need to set these environment variables correctly. 
For that just run `setup_env_vars.sh`

### SQL dialect

See `Makefile` for the valid `DATABASE` values.  Details for each dialect can be found in `tpcd.h`.  Adjust the query templates in `tpch-kit/dbgen/queries` as need be.

### Data generation

Data generation is done via `dbgen`.  See `./dbgen -h` for all options.  The environment variable `DSS_PATH` can be used to set the desired output location.

To generate the SF=1 (1GB), validation database population, use: `./dbgen -vf -s 1`

To generate updates for a SF=1 (1GB), use: `./dbgen -v -U 1 -s 1`

Then check your `DSS_PATH`. If there are no ".tbl" files there, it might be due to an issue with your environment variables. Try setting your environment variables manually in your terminal.

### Query generation

Query generation is done via `qgen`.  See `./qgen -h` for all options.

How to generate query by query: `./qgen -s 1 2 > q2.sql` where 1 represents the data scale factor and 2 is the query number (from 1 to 22). You can generate all the queries individually by running the script `individual_query_gen.sh`.

The following command can be used to generate all 22 queries in numerical order for the 1GB scale factor (`-s 1`) using the default substitution variables (`-d`).

```
./qgen -v -c -d -s 1 > tpch-stream.sql
```

### Database Creation

Create the database:
`createdb tpch`

Apply the schema:
`psql -d tpch -f dss.ddl`

Connect to the database:
`psql -d tpch`

Populate the database tables with data:
```
\copy nation FROM 'nation.tbl' WITH (FORMAT csv, DELIMITER '|');
\copy region FROM 'region.tbl' WITH (FORMAT csv, DELIMITER '|');
\copy customer FROM 'customer.tbl' WITH (FORMAT csv, DELIMITER '|');
\copy supplier FROM 'supplier.tbl' WITH (FORMAT csv, DELIMITER '|');
\copy part FROM 'part.tbl' WITH (FORMAT csv, DELIMITER '|');
\copy partsupp FROM 'partsupp.tbl' WITH (FORMAT csv, DELIMITER '|');
\copy orders FROM 'orders.tbl' WITH (FORMAT csv, DELIMITER '|');
\copy lineitem FROM 'lineitem.tbl' WITH (FORMAT csv, DELIMITER '|');
```

### How to run querys?
Just run: `psql -d tpch -f q1.sql`