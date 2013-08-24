--[[
	Generate a new node
--]]
function new_node()
	return {next = nil, parent = nil, tag = nil, content = "" }
end

--[[
	Tag list
--]]
local Tag = {
	-- Special tag
	["new_line"] = "",
	["text"] = "text",

	-- Title tag
	["title"] = "#",
	["subtitle"] = "##",
	["subsubtitle"] = "###",
	["list"] = "-"
}

function generate_tag(open, close, middle, middle_end)
	if middle == nil then
		middle = ""
	end
	if middle_end == nil then
		middle_end = ""
	end
	return {open_tag = open, middle_tag = middle, end_tag = close, middle_end_tag = middle_end}
end

local TagMap = {
	-- Special tag
	[Tag.new_line] = 		generate_tag("\n", "") ,
	[Tag.text] = 			generate_tag("<p>", "</p>"),

	-- Title tag
	[Tag.title] = 			generate_tag("<h1>", "</h1>"),
	[Tag.subtitle] = 		generate_tag("<h2>", "</h2>"),
	[Tag.subsubtitle] = 	generate_tag("<h3>", "</h3>"),
	[Tag.list] = 			generate_tag("<ul>\n\t<li>", "</li>\n</ul>", "\t<li>", "</li>")
}

--[[
	Return nil if there is an error in parsing
	otherwhise return the data structure of the document
--]]
function parse_file(filename)
	-- If something goes wrong exit
	local file = io.open(filename, "r")

	if  file == nil then
		return nil
	end

	local tree, first_element, new_node

	for line in file:lines() do
		new_node = parse_line(line)

		-- If is the first element
		if tree == nil then
			tree = new_node
			first_element = tree
		else
			tree.next = new_node
			tree.next.parent = tree
			tree = tree.next
		end
	end
	file:close()

	return first_element
end

--[[
--]]
function parse_line(line)

	local count = 0;
	local node = new_node()

	-- if there are no character
	if string.match(line, "%S+") == nil then
		node.tag = Tag.new_line
		node.content = Tag.new_line
		return node
	end

	-- eventuali change gmatch with gsub
	for word in string.gmatch(line, "%S+") do
		-- If is the first word in the line

		if count == 0 then

			if word == Tag.title then
				node.tag = Tag.title

			elseif word == Tag.subtitle then
				node.tag = Tag.subtitle

			elseif word == Tag.subsubtitle then
				node.tag = Tag.subsubtitle

			elseif word == Tag.list then
				node.tag = Tag.list

			else
				node.tag = Tag.text
				node.content = word
			end

		else
			node.content = node.content .. " " .. word
		end

		count = count + 1;
	end

	return node

end

function print_tree(tree)
	while tree ~= nil do
		print("(" .. tree.tag .. ", " .. tree.content .. ")" )
		tree = tree.next
	end
end

function generate_file(filename, tree)
	local file = io.open(filename, "w")
	local template = io.open("template.html", "r")

	local body = template:read("*all")
	template:close()

	if file == nill then return nil end

	local result = ""

	while tree ~= nil do
		local line = ""
		-- if the current tag is different from the
		-- previous add the tag
		if 	tree.parent == nil or tree.tag ~= tree.parent.tag then
			line = line .. TagMap[tree.tag].open_tag
		else
			line = line .. TagMap[tree.tag].middle_tag
		end

		line = line .. tree.content

		-- if the current tag is different from the
		-- next tag close the tag
		if tree.next == nil or tree.tag ~= tree.next.tag then
			line = line .. TagMap[tree.tag].end_tag
		else
			line = line .. TagMap[tree.tag].middle_end_tag
		end

		result = result .. line .. "\n"

		-- jump to the next node
		tree = tree.next
	end

	--print(body)
	result = string.gsub(body, "%[%[BODY%]%]", result)
	file:write( result )
	file:close()

	return true
end


-- Entry point
local parsed = parse_file("example.simplex")
if parsed == nil then print("ERROR - Can't open the file") end
print_tree(parsed)
generate_file("index.html", parsed)



