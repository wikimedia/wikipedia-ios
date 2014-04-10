Don't directly edit the files in the "assets" folder.

They are generated from the files in the "www" sub-folders via GruntJS compilation.

So edit the "www" files, if needed, then cd to "www" and run "grunt".

Notes:

- If new GruntJS dependencies are added to "www/Gruntfile.js" and "www/package.json" 
then you will need to cd to "www" and run "npm install" once to retrieve dependencies.
Then running "grunt" will work. 

- Running "npm install" pulls GruntJS dependencies into the "www/node_modules" folder.

- After running "grunt" you will probably need to delete the project's derived data
before building will reflect the changes. 

- Clear derived data in Xcode: "Window->Organizer->Projects->Wikipedia->Delete"