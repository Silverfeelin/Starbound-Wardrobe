ItemList = {}
ItemList.__index = ItemList

ItemList.default = {
  buffer = 10
}

--- Instantiates a new item list.
-- @param widgetName Name of the list widget.
-- @param addAction Function to call when a new item is added.
--  Function is invoked with params (listItemName, item, index).
-- @param itemsPerListItem Amount of items that can be added before a new list item is added to the list.
--  addFunction will be called for each item, but listItemName will be the same for this amount of times.
--  the index will indicate how many items have been added to the current list item (starting at 1).
-- @return Instance.
function ItemList.new(widgetName, addFunction, itemsPerListItem)
  local instance = {
    widget = widgetName,
    buffer = ItemList.default.buffer,
    addFunction = addFunction,
    itemsPerListItem = itemsPerListItem or 1,
    pending = {}
  }
  setmetatable(instance, ItemList)

  return instance
end

--- Clears all items from the list.
-- This also removes all pending items that were'nt added yet.
function ItemList:clear()
  self.pending = {}
  self.itemCount = 0
  widget.clearListItems(self.widget)
end

--- Sets the pending items to show.
-- This clears previous pending items, but does not clear the list.
-- @param items Items to show.
-- @see ItemList:clear
-- @see ItemList:enqueue
function ItemList:show(items)
  self.pending = {table.unpack(items)}
end

--- Enqueues the items
-- @param items Items to show.
function ItemList:enqueue(items)
  for _,item in ipairs(items) do
    table.insert(self.pending, item)
  end
end

--- Updates the list, adding `buffer` amount of pending items.
function ItemList:update()
  if not next(self.pending) then return end

  -- Number of items to add this update.
  local count = #self.pending
  if count > self.buffer then
    count = self.buffer
  end

  for i = 1, count do
    self:addNext()
  end
end

--- Adds the next pending item.
-- @return false if no item was added, addFunction result if an item was added.
function ItemList:addNext()
  if #self.pending == 0 then return false end

  local index = self:count() % self.itemsPerListItem + 1
  -- Add next list item
  if index == 1 then
    self.li = table.concat({self.widget, widget.addListItem(self.widget)}, ".")
  end

  -- Add item to current list item.
  local item = self.pending[1]
  table.remove(self.pending, 1)
  self.itemCount = self.itemCount + 1

  return self.addFunction(self.li, item, index)
end

--- Adds an empty item without using the pending items.
-- @return (listItem, index)
function ItemList:addEmpty()
  local index = self:count() % self.itemsPerListItem + 1
  -- Add next list item
  if index == 1 then
    self.li = table.concat({self.widget, widget.addListItem(self.widget)}, ".")
  end

  self.itemCount = self.itemCount + 1
  
  return self.li, index
end

function ItemList:count()
  return self.itemCount
end

--- Updates the buffers of one or more lists based on the time it took to update all lists.
-- @param itemLists Item lists that have been updated.
-- @param startTime os.clock() prior to updating all lists.
-- @param endTime os.clock() after updating all lists.
function ItemList.updateBuffers(itemLists, startTime, endTime)
  if #itemLists == 0 then return end

  local delta = endTime - startTime

  local d = 1
  if delta > 0.012 then
    d = -d
  elseif delta > 0.008 or itemLists[1].buffer >= ItemList.default.buffer then
    return -- No need to adjust buffers
  end

  -- Update buffer size
  for _,l in ipairs(c) do
    l.buffer = l.buffer + d
  end
end
