/*
    Solution for replicating SAS Function: propcase
    Function takes a string argument and returns it in Title Case

    Example:
    INPUT: 'teST eXamPLe'
    OUTPUT: 'Test Example'
*/
CREATE OR ALTER FUNCTION dbo.fn_get_proper_case(@txt as NVARCHAR(MAX))
RETURNS NVARCHAR(MAX)
as
begin
   declare @reset bit;
   declare @ret NVARCHAR(MAX);
   declare @i int;
   declare @c char(1);

   select @Reset = 1, @i=1, @Ret = '';
   
   while (@i <= len(@txt))
   	select @c= substring(@txt,@i,1),
               @ret = @ret + case when @reset=1 then UPPER(@c) else LOWER(@c) end,
               @reset = case when @c like '[a-zA-Z]' then 0 else 1 end,
               @i = @i +1
   return @ret
end;