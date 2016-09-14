create table pm_users (
	name varchar(64) not null primary key,
	password varchar(64) not null
);


create table pm_portfolios (
	id number not null primary key,
	name varchar(64) not null,
	username varchar(64) not null references pm_users(name) on delete cascade,
	cash number
);


create table pm_portfolio_contents (
	symbol varchar(64) not null references cs339.StocksSymbols(symbol) on delete cascade,
	pid number not null references pm_portfolios(id) on delete cascade,
	shares number not null,
	constraint pk_name primary key (symbol, pid)
);

create table pm_new_data (
	symbol varchar(64) not null references cs339.StocksSymbols(symbol) on delete cascade,
	timestamp number not null,
	open number not null,
	low number not null,
	high number not null,
	close number not null,
	volume number not null,
	constraint pk_data primary key (symbol,timestamp)
);

quit;
