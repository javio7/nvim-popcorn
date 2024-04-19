local SETTINGS = require 'springtime'.SETTINGS
local constants = require 'springtime.constants'

local M = {}

local function create_dynamic_section(section)
    local config = SETTINGS.spring[section] or require('springtime.' .. section)
    local values = config.values or require('springtime.' .. section).values

    local result = {}
    for i, v in pairs(values) do
        table.insert(result, { (config.selected == i and constants.CHECKED_ICON or constants.UNCHECKED_ICON) .. v })
    end
    return result
end

local function select_or_unselect(lines, line_nr)
    for _, v in pairs(lines) do
        if v == line_nr then
            local selected = vim.fn.getline('.')
            local final = tostring(selected):gsub(constants.UNCHECKED_ICON, constants.CHECKED_ICON)
            vim.fn.setline(line_nr, final)
        else
            local unselected = vim.fn.getline(v)
            local final = tostring(unselected):gsub(constants.CHECKED_ICON, constants.UNCHECKED_ICON)
            vim.fn.setline(v, final)
        end
    end
end

function M.selection_key_event()
    vim.cmd [[setl ma]]
    local line_nr = vim.fn.line('.')

    if line_nr > 1 and line_nr < 5 then
        local lines = { 2, 3, 4 }
        select_or_unselect(lines, line_nr)
    end

    if line_nr > 6 and line_nr < 10 then
        local lines = { 7, 8, 9 }
        select_or_unselect(lines, line_nr)
    end

    if line_nr > 11 and line_nr < 14 then
        local lines = { 12, 13 }
        select_or_unselect(lines, line_nr)
    end

    if line_nr > 15 and line_nr < (M.java_version_section - 1) then
        local lines = {}
        for i = 15, M.java_version_section - 1 do table.insert(lines, i) end
        select_or_unselect(lines, line_nr)
    end

    if line_nr > M.java_version_section and line_nr < (M.project_metadata_section - 1) then
        local lines = {}
        for i = M.java_version_section, M.project_metadata_section - 1 do table.insert(lines, i) end
        select_or_unselect(lines, line_nr)
    end

    vim.cmd [[setl noma]]
end

function M.create_content()
    local style = SETTINGS.dialog.style.section_link
    local content = {
        { constants.PROJECT_SECTION, style },
        { (SETTINGS.spring.project.selected == 1 and constants.CHECKED_ICON or constants.UNCHECKED_ICON) .. constants.GRADLE_GROOVY },
        { (SETTINGS.spring.project.selected == 2 and constants.CHECKED_ICON or constants.UNCHECKED_ICON) .. constants.GRADLE_KOTLIN },
        { (SETTINGS.spring.project.selected == 3 and constants.CHECKED_ICON or constants.UNCHECKED_ICON) .. constants.MAVEN },
        { "" },
        { constants.LANGUAGE_SECTION, style },
        { (SETTINGS.spring.language.selected == 1 and constants.CHECKED_ICON or constants.UNCHECKED_ICON) .. constants.JAVA },
        { (SETTINGS.spring.language.selected == 2 and constants.CHECKED_ICON or constants.UNCHECKED_ICON) .. constants.KOTLIN },
        { (SETTINGS.spring.language.selected == 3 and constants.CHECKED_ICON or constants.UNCHECKED_ICON) .. constants.GROOVY },
        { "" },
        { constants.PACKAGING_SECTION, style },
        { (SETTINGS.spring.packaging.selected == 1 and constants.CHECKED_ICON or constants.UNCHECKED_ICON) .. constants.JAR },
        { (SETTINGS.spring.packaging.selected == 2 and constants.CHECKED_ICON or constants.UNCHECKED_ICON) .. constants.WAR },
        { "" },
        { constants.SPRING_BOOT_SECTION, style }
    }

    local spring_boot = create_dynamic_section("spring_boot")

    local java_version_label = {
        { "" },
        { constants.JAVA_VERSION_SECTION, style }
    }

    local java_version = create_dynamic_section("java_version")
    M.java_version_section = #spring_boot + 17

    M.project_metadata_section = M.java_version_section + #java_version + 2

    local project_metadata = {
        { "" },
        { constants.PROJECT_METADATA_SECTION, style },
        { "Group        󰁕 " .. SETTINGS.spring.project_metadata.group },
        { "Artifact     󰁕 " .. SETTINGS.spring.project_metadata.artifact },
        { "Name         󰁕 " .. SETTINGS.spring.project_metadata.name },
        { "Package Name 󰁕 " .. SETTINGS.spring.project_metadata.package_name },
        { "" },
        { constants.DEPENDENCIES_SECTION, style },
        { "" }
    }

    local function add_to_content(values)
        for _, v in pairs(values) do
            table.insert(content, v)
        end
    end

    add_to_content(spring_boot)
    add_to_content(java_version_label)
    add_to_content(java_version)
    add_to_content(project_metadata)

    return content
end

local function project_to_id(value)
    if value == constants.GRADLE_GROOVY then
        return "gradle-project"
    end
    if value == constants.GRADLE_KOTLIN then
        return "gradle-project-kotlin"
    end
    return "maven-project"
end

function M.generate(values)
    local user_input = "y"
    if SETTINGS.dialog.confirmation then
        user_input = vim.fn.input(string.format("Do you want to generate project [%s]? y/n: ", values[8]))
    end

    if tostring(user_input):lower() == "y" then
        vim.cmd[[redraw]]
--         print(vim.inspect(values)) -- TODO replace with logger
        require'springtime_rs'.create_project {
            project = project_to_id(values[1]),
            language = tostring(values[2]):lower(),
            packaging = tostring(values[3]):lower(),
            spring_boot = values[4],
            java_version = values[5],
            project_group = values[6], -- TODO validate not empty
            project_artifact = values[7],-- TODO validate not empty
            project_name = values[8],-- TODO validate not empty
            project_package_name = values[9],-- TODO validate not empty
            project_version = SETTINGS.spring.project_metadata.version,
            dependencies = values[10],
            path = SETTINGS.directory.path,
            decompress = SETTINGS.directory.decompress,
            log_debug = SETTINGS.internal.log_debug
        }
    else
        vim.cmd[[redraw]]
    end
end

return M
