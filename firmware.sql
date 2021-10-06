/*
# The latest firmware releases

create table latest_fw
(
	board_id varchar(100) not null,
	fw_ver varchar(20) not null,
	checkdate date not null,
	primary key (board_id)
);

*/

insert into latest_fw values('MT_0000000451','20.29.2002','2021-10-06');


