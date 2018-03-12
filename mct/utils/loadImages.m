function cameraListImages = loadImages(cameras, image_directory, num_frames, start_frame, dataset)
    if strcmp(dataset, 'hda')
        for j=start_frame:(start_frame + num_frames)
            cameraListImages{j+1} = strcat(image_directory, '/', num2str(j), '.png');
        end
    elseif strcmp(dataset, 'campus2')
      if start_frame == 1 % Camera 1
        dinfo = dir('~/Campus_II/frames_alameda_noon_1_6_2017');
        cameraListImages = {dinfo.name};
        cameraListImages = natsortfiles(cameraListImages);
        cameraListImages(:,1:2) = [];
        cameraListImages = strcat('~/Campus_II/frames_alameda_noon_1_6_2017', '/', cameraListImages);
      elseif start_frame == 2 % Camera 2
        dinfo = dir('~/Campus_II/frames_central_noon_1_6_2017');
        cameraListImages = {dinfo.name};
        cameraListImages = natsortfiles(cameraListImages);
        cameraListImages(:,1:2) = [];
        cameraListImages = strcat('~/Campus_II/frames_central_noon_1_6_2017', '/', cameraListImages);
      end
    end
