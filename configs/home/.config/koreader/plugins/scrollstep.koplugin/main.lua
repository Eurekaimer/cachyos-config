--[[--
Adds Vim/Sioyek-style navigation to the reader and File Manager.

Reader Ctrl+J/K pans 30% of the screen in scroll mode and turns one page in
page mode/PDFs. History keeps per-book letter shortcuts except reserved `f`,
adds Ctrl+J/K list paging, and uses `f` to return to the File Browser. The
File Manager reserves `h` for opening History while keeping its other per-item
letter shortcuts. The top reader menu supports j/k focus movement, h to go
back, and l to select. Reader r opens the native custom-title editor for the
current document.

@module koplugin.ScrollStep
--]]--

local Device = require("device")
local DocSettings = require("docsettings")
local Dispatcher = require("dispatcher")  -- luacheck: ignore
local Event = require("ui/event")
local InputDialog = require("ui/widget/inputdialog")
local InfoMessage = require("ui/widget/infomessage")
local logger = require("logger")
local WidgetContainer = require("ui/widget/container/widgetcontainer")
local UIManager = require("ui/uimanager")
local _ = require("gettext")

local STEP_FRACTION = 0.3

local ScrollStep = WidgetContainer:extend{
    name = "scrollstep",
    is_doc_only = false,
}

function ScrollStep:onDispatcherRegisterActions()
    Dispatcher:registerAction("scroll_step_down", {
        category = "none",
        event = "ScrollStepDown",
        title = _("Scroll down 30% of the screen"),
        reader = true,
    })
    Dispatcher:registerAction("scroll_step_up", {
        category = "none",
        event = "ScrollStepUp",
        title = _("Scroll up 30% of the screen"),
        reader = true,
    })
    Dispatcher:registerAction("edit_book_title", {
        category = "none",
        event = "EditBookTitle",
        title = _("Edit custom book title"),
        reader = true,
    })
end

local function withoutShortcut(shortcuts, reserved)
    local filtered = {}
    for _, shortcut in ipairs(shortcuts) do
        if shortcut ~= reserved then
            table.insert(filtered, shortcut)
        end
    end
    return filtered
end

function ScrollStep:configureHistoryMenu(menu)
    if not menu then return end

    -- Keep History's per-book shortcuts, but reserve F for returning to the
    -- File Browser. Ctrl+J/K do not collide with the plain J/K item shortcuts.
    menu.item_shortcuts = withoutShortcut(menu.item_shortcuts, "F")
    menu.is_enable_shortcut = true
    menu.key_events.SelectByShortCut = { { menu.item_shortcuts } }
    menu.key_events.ScrollStepHistoryNextPage = { { "Ctrl", "J" } }
    menu.key_events.ScrollStepHistoryPrevPage = { { "Ctrl", "K" } }
    menu.key_events.ScrollStepHistoryFileManager = {
        { "F" },
        { "Ctrl", "F" },
    }

    menu.onScrollStepHistoryNextPage = function(history_menu)
        logger.dbg("ScrollStep: paging History forward")
        history_menu:onNextPage()
        return true
    end
    menu.onScrollStepHistoryPrevPage = function(history_menu)
        logger.dbg("ScrollStep: paging History backward")
        history_menu:onPrevPage()
        return true
    end
    local ui = self.ui
    menu.onScrollStepHistoryFileManager = function(history_menu)
        logger.dbg("ScrollStep: leaving History for File Browser")
        history_menu:onCloseAllMenus()
        if ui.document then
            ui:onHome()
        end
        return true
    end
    menu:updateItems()
end

function ScrollStep:configureFileManagerMenu(menu)
    if not menu then return end

    -- Reserve H for History, retaining all other per-file letter shortcuts.
    menu.item_shortcuts = withoutShortcut(menu.item_shortcuts, "H")
    menu.key_events.SelectByShortCut = { { menu.item_shortcuts } }
    menu.key_events.ScrollStepShowHistory = { { "H" } }
    local history = self.ui.history
    menu.onScrollStepShowHistory = function()
        logger.dbg("ScrollStep: opening History from File Manager")
        history:onShowHist()
        return true
    end
    menu:updateItems()
end

function ScrollStep:configureTocMenu(menu)
    if not menu then return end

    menu.key_events.ScrollStepTocNextPage = { { "Ctrl", "J" } }
    menu.key_events.ScrollStepTocPrevPage = { { "Ctrl", "K" } }
    menu.onScrollStepTocNextPage = function(toc_menu)
        logger.dbg("ScrollStep: paging Table of Contents forward")
        toc_menu:onNextPage()
        return true
    end
    menu.onScrollStepTocPrevPage = function(toc_menu)
        logger.dbg("ScrollStep: paging Table of Contents backward")
        toc_menu:onPrevPage()
        return true
    end
end

function ScrollStep:configureReaderMenu(menu)
    if not menu or not menu.onFocusMove or menu._scrollstep_vim_navigation then return end

    menu._scrollstep_vim_navigation = true
    menu.key_events.ScrollStepMenuDown = { { "J" } }
    menu.key_events.ScrollStepMenuUp = { { "K" } }
    menu.key_events.ScrollStepMenuBack = { { "H" } }
    menu.key_events.ScrollStepMenuSelect = { { "L" } }
    menu.onScrollStepMenuDown = function(reader_menu)
        reader_menu:onFocusMove({ 0, 1 })
        return true
    end
    menu.onScrollStepMenuUp = function(reader_menu)
        reader_menu:onFocusMove({ 0, -1 })
        return true
    end
    menu.onScrollStepMenuBack = function(reader_menu)
        reader_menu:onBack()
        return true
    end
    menu.onScrollStepMenuSelect = function(reader_menu)
        reader_menu:onPress()
        return true
    end
end

function ScrollStep:installTocBindings()
    local toc = self.ui and self.ui.toc
    if not toc or toc._scrollstep_original_onShowToc then return end

    local original_onShowToc = toc.onShowToc
    toc._scrollstep_original_onShowToc = original_onShowToc
    toc.onShowToc = function(toc_module, ...)
        local result = original_onShowToc(toc_module, ...)
        self:configureTocMenu(toc_module.toc_menu)
        return result
    end
    self:configureTocMenu(toc.toc_menu)
end

function ScrollStep:installReaderMenuBindings()
    local reader_menu = self.ui and self.ui.menu
    if not reader_menu or reader_menu._scrollstep_original_onShowMenu then return end

    local original_onShowMenu = reader_menu.onShowMenu
    reader_menu._scrollstep_original_onShowMenu = original_onShowMenu
    reader_menu.onShowMenu = function(menu_module, ...)
        local result = original_onShowMenu(menu_module, ...)
        self:configureReaderMenu(menu_module.menu_container and menu_module.menu_container[1])
        return result
    end
end

function ScrollStep:installHistoryBindings()
    local history = self.ui and self.ui.history
    if not history or history._scrollstep_original_onShowHist then return end

    local original_onShowHist = history.onShowHist
    history._scrollstep_original_onShowHist = original_onShowHist
    history.onShowHist = function(history_module, ...)
        local result = original_onShowHist(history_module, ...)
        self:configureHistoryMenu(history_module.booklist_menu)
        return result
    end

    -- Also cover plugin reloads while History is already open.
    self:configureHistoryMenu(history.booklist_menu)
end

function ScrollStep:init()
    self:installHistoryBindings()
    if self.ui.document then
        self:installTocBindings()
        self:installReaderMenuBindings()
        self:onDispatcherRegisterActions()
    else
        self.ui:registerPostInitCallback(function()
            self:configureFileManagerMenu(self.ui.file_chooser)
        end)
    end
end

local function saveCustomTitle(ui, title)
    local file = ui.document.file
    local original_props = ui.doc_settings:readSetting("doc_props") or {}
    local custom_metadata_file = DocSettings:findCustomMetadataFile(file)
    local custom_doc_settings = custom_metadata_file
        and DocSettings.openSettingsFile(custom_metadata_file) or DocSettings.openSettingsFile()
    if not custom_metadata_file then
        custom_doc_settings:saveSetting("doc_props", original_props)
    end
    local custom_props = custom_doc_settings:readSetting("custom_props", {})
    local old_title = custom_props.title or original_props.title
    custom_props.title = title
    custom_doc_settings:saveSetting("custom_props", custom_props)
    if not custom_doc_settings:flushCustomMetadata(file) then
        error("failed to write custom metadata")
    end

    ui.doc_props.title = title
    ui.doc_props.display_title = title
    UIManager:broadcastEvent(Event:new("InvalidateMetadataCache", file))
    UIManager:broadcastEvent(Event:new("BookMetadataChanged", {
        filepath = file,
        doc_props = ui.doc_props,
        metadata_key_updated = "title",
        metadata_value_old = old_title,
    }))
end

function ScrollStep:onEditBookTitle()
    local ui = self.ui
    if not ui or not ui.document or not ui.doc_settings or not ui.doc_props then return end

    local input_dialog
    local function cancel()
        UIManager:close(input_dialog)
        return true
    end
    local function save()
        local title = input_dialog:getInputValue()
        if not title or title == "" then return true end
        local ok, err = pcall(saveCustomTitle, ui, title)
        if not ok then
            logger.err("ScrollStep: failed to save custom book title:", err)
            UIManager:show(InfoMessage:new{
                text = _("Failed to save custom book title."),
            })
            return true
        end
        UIManager:close(input_dialog)
        return true
    end

    input_dialog = InputDialog:new{
        title = _("Edit custom book title")
            .. " — English (Ctrl+E) / IME (Ctrl+I)",
        input = ui.doc_props.title or ui.doc_props.display_title or "",
        buttons = {
            {
                {
                    text = _("Cancel") .. " (Ctrl+Q)",
                    id = "close",
                    callback = cancel,
                },
                {
                    text = _("Save") .. " (Ctrl+S)",
                    is_enter_default = true,
                    callback = save,
                },
            },
        },
    }
    UIManager:show(input_dialog)
    input_dialog:onShowKeyboard()

    local input_widget = input_dialog._input_widget
    local direct_input = false
    local setDirectInput
    local fcitx_remote = io.open("/usr/bin/fcitx5-remote", "r")
    if fcitx_remote then
        fcitx_remote:close()
        direct_input = true
        setDirectInput = function(enabled)
            direct_input = enabled
            if enabled then
                Device:stopTextInput()
                os.execute("/usr/bin/fcitx5-remote -c >/dev/null 2>&1")
            else
                Device:startTextInput()
                os.execute("/usr/bin/fcitx5-remote -o >/dev/null 2>&1")
            end
            return true
        end
        setDirectInput(true)
        UIManager:scheduleIn(0.1, function() setDirectInput(true) end)
    end

    local shifted_key_chars = {
        ["1"] = "!", ["2"] = "@", ["3"] = "#", ["4"] = "$", ["5"] = "%",
        ["6"] = "^", ["7"] = "&", ["8"] = "*", ["9"] = "(", ["0"] = ")",
        ["-"] = "_", ["="] = "+", ["["] = "{", ["]"] = "}", ["\\"] = "|",
        [";"] = ":", ["'"] = "\"", [","] = "<", ["."] = ">", ["/"] = "?",
        ["`"] = "~",
    }
    local plain_ascii = {
        ["-"] = true, ["="] = true, ["["] = true, ["]"] = true, ["\\"] = true,
        [";"] = true, ["'"] = true, [","] = true, ["."] = true, ["/"] = true,
        ["`"] = true,
    }
    local function getDirectAscii(key)
        local key_name = key.key
        if type(key_name) ~= "string" then return end
        if key_name:match("^[A-Z]$") then
            return key["Shift"] and key_name or key_name:lower()
        end
        if key_name:match("^[0-9]$") then
            return key["Shift"] and shifted_key_chars[key_name] or key_name
        end
        if key_name == " " then return " " end
        if plain_ascii[key_name] then
            return key["Shift"] and shifted_key_chars[key_name] or key_name
        end
    end

    -- InputText bypasses InputContainer's key_events on this KOReader build.
    -- In English mode, insert printable ASCII from KeyPress and suppress the
    -- broken Fcitx TextInput translation. IME mode keeps native TextInput.
    local original_onKeyPress = input_widget.onKeyPress
    local original_onTextInput = input_widget.onTextInput
    input_widget.onKeyPress = function(widget, key)
        if key["Ctrl"] and not key["Shift"] and not key["Alt"] then
            if key["Q"] then return cancel() end
            if key["S"] then return save() end
            if setDirectInput then
                if key["E"] then return setDirectInput(true) end
                if key["I"] then return setDirectInput(false) end
            end
        elseif direct_input and not key["Alt"] and not key["ScreenKB"] then
            local char = getDirectAscii(key)
            if char then
                if #widget.charlist == 0 then widget.charpos = 1 end
                table.insert(widget.charlist, widget.charpos, char)
                widget.charpos = widget.charpos + 1
                widget.undo_charlist = nil
                widget.is_text_edited = true
                widget:initTextBox(nil, true)
                return true
            end
        end
        return original_onKeyPress(widget, key)
    end
    input_widget.onTextInput = function(widget, text)
        if direct_input then return true end
        return original_onTextInput(widget, text)
    end
    return true
end

function ScrollStep:scrollStep(direction)
    local ui = self.ui
    if not ui then return end
    if ui.rolling then
        if ui.view.view_mode == "scroll" then
            ui.rolling:_gotoPos(ui.rolling.current_pos + direction * STEP_FRACTION * ui.dimen.h)
        else
            ui.rolling:onGotoViewRel(direction)
        end
    elseif ui.paging then
        ui.paging:onGotoViewRel(direction)
    end
end

-- Dispatcher path (bare reader): used by the hotkeys bindings.
function ScrollStep:onScrollStepDown()
    self:scrollStep(1)
    return true
end

function ScrollStep:onScrollStepUp()
    self:scrollStep(-1)
    return true
end

return ScrollStep
