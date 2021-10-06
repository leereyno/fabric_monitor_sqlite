/*
Lee Reynolds <Lee.Reynolds@asu.edu>
ASU Research Computing
*/

/* DENORMALIZED VIEW OF SYSTEM DATA */

create view combined as

	select
		hosts.uuid as uuid,
		hosts.hostname,
		hosts.osflavor,
		hosts.osversion,
		hosts.centosversion,
		hosts.oskernel,
		hosts.vendor,
		hosts.model,
		hosts.serial,
		hosts.biosdate,
		hosts.biosvend,
		hosts.biosver,
		hosts.infiniband,
		hosts.omnipath,
		hosts.opaversion,
		hosts.smt,
		devices.device,
		devices.board_id,
		devices.fw_ver,
		devices.hca_type,
		ports.port,
		ports.lid,
		ports.link_layer,
		ports.phys_state,
		ports.rate,
		ports.sm_lid,
		ports.state,
		datetime(hosts.updatetime, 'unixepoch') as updatetime
	from
		hosts
	left join devices on	
		hosts.uuid = devices.uuid
	left join ports on 
		( devices.uuid = ports.uuid and devices.device = ports.device );

/* BAD PORTS */

create view badports as

	select
		hostname,
		device,
		hca_type,
		port,
		link_layer,
		rate,
		phys_state,
		state, 
		updatetime
	from 
		combined 
	where 
		link_layer !='Ethernet'
	and
		(phys_state != '5: LinkUp' or state != '4: ACTIVE')
	order by hostname;

/* FIRMWARE CHECK */

create view fw_check as

	select
		combined.hostname,
		 combined.device,
		 combined.board_id,
		 combined.port,
		 combined.link_layer,
		 combined.fw_ver as loaded_fw,
		 latest_fw.fw_ver as latest_fw,
		 combined.updatetime
	from
		combined
	inner join latest_fw
		on combined.board_id = latest_fw.board_id and combined.fw_ver != latest_fw.fw_ver
	order by
		combined.board_id,hostname;

create view bios_check as

	select
		hosts.hostname,
		hosts.vendor,
		hosts.model,
		hosts.biosver as loaded_bios,
		latest_bios.biosver as latest_bios,
		datetime(hosts.updatetime, 'unixepoch') as updatetime
	from
		hosts
	inner join latest_bios on 
		hosts.vendor = latest_bios.vendor
	and 
		hosts.model = latest_bios.model
	and
		hosts.biosver != latest_bios.biosver
	order by
		hosts.vendor,hosts.model,hosts.hostname;


create view host_ips as 

	select
		hosts.hostname,
		ip_info.uuid,
		ip_info.ifname,
		ip_info.mac,
		ip_info.ip,
		ip_info.netmask,
		ip_info.duplex,
		ip_info.mtu,
		ip_info.operstate,
		ip_info.speed,
		datetime(ip_info.updatetime, 'unixepoch') as updatetime
	from
		hosts
	inner join ip_info on
		hosts.uuid = ip_info.uuid
	order by
		hosts.hostname,ip_info.ifname;
	

