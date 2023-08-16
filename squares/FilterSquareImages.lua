local LrTasks = import 'LrTasks'
local LrFunctionContext = import 'LrFunctionContext'
local LrDialogs = import 'LrDialogs'
local LrProgressScope = import 'LrProgressScope'
local LrApplication = import 'LrApplication'  -- Ensure this is imported

local function filterSquareImages()
    LrTasks.startAsyncTask(function()
        
        LrFunctionContext.callWithContext("filterSquareImages", function(context)
            
            local progressScope = LrProgressScope {
                title = "Searching the catalog...",
            }

            local catalog = LrApplication.activeCatalog()
            local photos = catalog:getAllPhotos()
            local squarePhotos = {}

            for i, photo in ipairs(photos) do
                if progressScope:isCanceled() then
                    return
                end

                local croppedDimensions = photo:getFormattedMetadata('croppedDimensions')
                local croppedWidth, croppedHeight = croppedDimensions:match("(%d+) x (%d+)")
                croppedWidth = tonumber(croppedWidth)
                croppedHeight = tonumber(croppedHeight)

                if croppedWidth and croppedHeight and croppedWidth == croppedHeight then
                    table.insert(squarePhotos, photo)
                end

                progressScope:setPortionComplete(i, #photos)
            end

            progressScope:done()
            
            if #squarePhotos > 0 then
                catalog:withWriteAccessDo("Create Squares Collection", function()
                    local squaresCollection = catalog:createCollection("Squares", nil, true)
                    squaresCollection:addPhotos(squarePhotos)
                end)
            end

            -- Show the result
            if #squarePhotos == 0 then
                LrDialogs.message("No square images found!")
            else
                LrDialogs.message(string.format("Found %d square (edited) images and added them to the 'Squares' collection!", #squarePhotos))
            end

        end)
    end)
end

filterSquareImages()

