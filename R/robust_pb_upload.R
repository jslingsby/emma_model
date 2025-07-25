#' @note This version forces overwriting of the files in the release, and uses a lot of GH queries.  Best reserved for cases you expect to fail
robust_pb_upload <- function(files,
                             repo="AdamWilsonLab/emma_model",
                             tag,
                             max_attempts = 10,
                             sleep_time = 1,
                             temp_directory = "data/temp/pb_test",
                             ...){



  # check/create release

    assets <- pb_list(repo = repo)

    if(!tag %in% assets$tag){

      caught<-tryCatch(pb_new_release(repo = repo,
                                      tag = tag),
                       error = function(e) e)

      if(exists("caught")){rm(caught)}

    }


  # create dir if needed

    if(!dir.exists(temp_directory)){dir.create(temp_directory,recursive = TRUE)}


  # loop through files


  for(i in 1:length(files)){

    message("attempting to upload file ", i, " of ",length(files),": ",files[i])

    attempts <- 1

    while(attempts < max_attempts){

      message("attempt ", attempts, " of ", max_attempts)


      #try to upload the file

      pb_upload(file = files[i],
                repo = repo,
                tag = tag,
                overwrite = TRUE)

      # as far as I can tell, the only way to figure out if an upload was broken is that the file in question is shown on the repo but can't be downloaded

      #check if the file was properly uploaded

      repo_status <- pb_list(repo = repo,tag = tag)

      if(basename(files[i]) %in% repo_status$file_name){

        file_uploaded <- TRUE

      }else{

          file_uploaded <- FALSE

          }

      #if the file wasn't even uploaded, skip to the next attempt without trying to downloaded

        if(!file_uploaded){

          attempts <- attempts+1

          next

        }

      # attempt to download the file

        pb_download(file = basename(files[i]),
                    dest = temp_directory,
                    repo = repo,
                    tag = tag)

     # record if file was successfully downloaded

      if(file.exists(file.path(temp_directory,basename(files[i])))){

        file_downloaded <- TRUE

      }else{

          file_downloaded <- FALSE

          }

    # if file was uploaded break out of the loop

      if(file_uploaded & file_downloaded){


        file.remove(file.path(temp_directory,basename(files[i])))

        break

        }

    # otherwise, increment

      attempts = attempts+1

    # and pause
      Sys.sleep(sleep_time)

    #message if failed
      if(attempts >= max_attempts){
        message("Uploading file ",files[i] ," failed. Giving up.")

      }

    }#while loop
  }# i files loop



  return(as.character(Sys.Date()))

}

##########################
