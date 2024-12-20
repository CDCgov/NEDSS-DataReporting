
create or alter view dbo.v_nrt_srte_totalidm as 
select
	unique_cd  ,
	SRT_reference as SRT_reference ,
	format as format ,
	label as label 
	from nbs_srte..totalidm;

create or alter view dbo.v_nrt_srte_imrdbmapping as 
select * from nbs_srte..imrdbmapping;

create or alter view dbo.v_nrt_srte_codeset as 
select * from nbs_srte..codeset;

create or alter view dbo.v_nrt_srte_code_value_general as select * from nbs_srte..Code_Value_General v;

