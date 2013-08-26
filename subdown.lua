--[[
	Tag list
--]]
local Tag = {
	-- Special tag
	new_line = "",
	text = "",

	-- Title tag
	title = "#",
	subtitle = "##",
	subsubtitle = "###",

	-- List tag
	list = "*",
	sublist = "\t*",

	-- Text tag
	italic = "_%S",
	bold = "__%S"
}

--[[
	Generate a tag with default value for fill the TagMap
--]]
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

	-- List tag
	[Tag.list] = 			generate_tag("<ul>\n\t<li>", "</li>\n</ul>", "\t<li>", "</li>"),
	[Tag.sublist] = 		generate_tag("<ul>\n\t<li>", "</li>\n</ul>", "\t<li>", "</li>"),

	-- Text tag
	[Tag.italic] = 			generate_tag("<it>", "</it>"),
	[Tag.bold] = 			generate_tag("<strong>", "</strong>"),
}

--[[
	Generate a new node
--]]
function new_node()
	return {next = nil, parent = nil, tag = nil, content = "" }
end


function parse(file)
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


function parse_line(line)

	local node = new_node()

	-- First word
	local word_pos, word_pos_end = string.find(line, "%S+")

	-- If the string contains only space is empty
	if word_pos == nil then
		print("Setting new line tag")
		node.tag = Tag.new_line
		node.content = Tag.new_line
		return node
	end

	local word = string.sub(line, word_pos, word_pos_end)

	-- Check the tag at the beginning of a line ...
	if word == Tag.title then
		node.tag = Tag.title
		print("Setting title tag")

	elseif word == Tag.subtitle then
		node.tag = Tag.subtitle
		print("Setting subtitle tag")

	elseif word == Tag.subsubtitle then
		node.tag = Tag.subsubtitle
		print("Setting subsubtitle tag")

	elseif word == Tag.list then
		if 	is_indented(line, word_pos) then
			node.tag = Tag.sublist
			print("Setting sublist tag")
		else
			node.tag = Tag.list
			print("Setting list tag")
		end
	else
		print("Setting text tag")
		node.tag = Tag.text
		word_pos = 0
	end

	-- ... checking italic and bold tag
	while string.find(line, Tag.italic, word_pos ) do
		local bold_tag = string.find(line, Tag.bold, word_pos)
		local italic_tag = string.find(line, Tag.italic, word_pos)

		if bold_tag ~= nil or italic_tag ~= nil then
			local subnode = new_node() -- The node with the text tag

			if bold_tag ~= nil then
				subnode.tag = Tag.bold
				node.content = string.sub(line, word_pos+1, bold_tag)
				word_pos = bold_tag
			elseif italic_tag ~= nil then
				subnode.tag = Tag.italic
				node.content = string.sub(line, word_pos+1, italic_tag)
				word_pos = italic_tag
			end
			subnode.content = ""
			node.next = subnode
			node = node.next
		end
	end -- end while

	print( word_pos .. " word = " .. word )

	node.content = string.sub(line, word_pos + string.len(node.tag) )

	return node

end

function is_indented(line, position)
	if 	string.sub(line, position-1, position-1) == "\t" or -- if is a tabulation
		(string.sub(line, position-1, position-1) == " " and position >= 4) then -- or have at least 4 spaces
		return true
	end
	return false
end

function generate_file(filename, tree)
	local file = io.open(filename, "w")

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

	local template = io.open("template.html", "r")
	local body = template:read("*all")
	template:close()

	result = string.gsub(body, "%[%[BODY%]%]", result)
	file:write( result )
	file:close()

	return true
end

-- Entry point
local file = io.open("example.subdown", "r")
if  file == nil then
	print("ERROR - Can't open the file")
	return
end
local f = parse(file) -- Parse the file
generate_file("index.html", f) -- Apply the TagMap



