//
//  OpenAndSaveDialogues.swift
//  WorkoutEditor
//
//  Created by Steven Lord on 09/09/2019.
//  Copyright © 2019 Steven Lord. All rights reserved.
//

import Cocoa

class OpenAndSaveDialogues{
    
    
    
    func selectedPath(withTitle title: String, andFileTypes fileTypes: [String], directory: URL?) -> URL?{
        
        let dialog = NSOpenPanel()
        
        dialog.title                   = title
        dialog.showsResizeIndicator    = true
        dialog.showsHiddenFiles        = false
        dialog.canChooseDirectories    = true
        dialog.canCreateDirectories    = true
        dialog.allowsMultipleSelection = false
        dialog.allowedFileTypes        = fileTypes
        
        if let dir = directory{
            dialog.directoryURL = dir
        }
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            return dialog.url // Pathname of the file
        } else {
            // User clicked on "Cancel"
            return nil
        }
    }
    
    func saveFilePath(suggestedFileName: String, allowFileTypes: [String], directory: URL?) -> URL?{
        
        let panel = NSSavePanel()
        panel.directoryURL = directory ?? FileManager.default.homeDirectoryForCurrentUser
        panel.allowedFileTypes = allowFileTypes
        panel.canCreateDirectories = true
        panel.nameFieldStringValue = suggestedFileName
        
        
        if panel.runModal() == NSApplication.ModalResponse.OK{
            return panel.url
        }
        
        return nil
        
    }
    
    func chooseFolderForSave(createSubFolder folder: String? = nil) -> URL?{
        //see about selecting a directory for the save
        let dialog = NSOpenPanel()
        dialog.message = "Choose directory for save."
        if let f = folder{
            dialog.message = "Choose directory for save. (a sub folder called \(f) will be created"
        }
        dialog.showsResizeIndicator     = true
        dialog.showsHiddenFiles         = false
        dialog.canChooseDirectories     = true
        dialog.canCreateDirectories     = true
        dialog.allowsMultipleSelection  = false
        dialog.canChooseFiles           = false
        dialog.prompt = "Select"
        
        if (dialog.runModal() == NSApplication.ModalResponse.OK) {
            if let directory = dialog.url{
                var saveFolder = directory
                if let f = folder{
                    saveFolder = directory.appendingPathComponent(f)
                }
                
                //check for this folder
                var isDirectory: ObjCBool = false
                FileManager.default.fileExists(atPath: saveFolder.path, isDirectory: &isDirectory)
                
                if !isDirectory.boolValue{
                    print("\(saveFolder) does not exist. Will create")
                    do{
                        try FileManager.default.createDirectory(at: saveFolder, withIntermediateDirectories: true, attributes: nil)
                    }catch{
                        print(error)
                        return nil
                    }
                }
                return saveFolder
                
            }
        }
        
        return nil
    }
    
    
    
    
}
