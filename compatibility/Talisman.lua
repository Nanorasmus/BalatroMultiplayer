to_big = to_big or function(x, y)
	return x
end

String_to_number = Big and Big.parse
and function(x)
	if not x or x == "" or x == "0" or x == 0 then
		return to_big(0)
	end
	return Big:parse(x)

	end
or function(x)
	if x == "" then
		return 0
	end
	return tonumber(x)
end