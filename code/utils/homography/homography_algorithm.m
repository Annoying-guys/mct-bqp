function [Hs, cam_dets_gnd, cam_region_gnd] = homography_algorithm(matchings, inplanes, ground_plane_regions, homog_solver, N, rho_r, rho_d, debug, min_delta)
    %-----------------------------PREAMBLE---------------------------------
    cam1_region_cam = inplanes{1};
    cam2_region_cam = inplanes{2};
    cam1_region_gnd = ground_plane_regions{1}(1:end-1,:);
    cam2_region_gnd = ground_plane_regions{2}(1:end-1,:);
    cam1_dets_cam = [matchings{1}(:,4) + matchings{1}(:,6)./2 matchings{1}(:,5) + matchings{1}(:,7)];
    cam2_dets_cam = [matchings{2}(:,4) + matchings{2}(:,6)./2 matchings{2}(:,5) + matchings{2}(:,7)];
    cam1_dets_gnd = matchings{1}(:,8:9);
    cam2_dets_gnd = matchings{2}(:,8:9);
    cam1_region_gnd_original = cam1_region_gnd;
    cam2_region_gnd_original = cam2_region_gnd;
    cam1_dets_gnd_original = cam1_dets_gnd;
    cam2_dets_gnd_original = cam2_dets_gnd;
    %-----------------------------ITERATIVE PROCESS---------------------------------
    if strcmp(debug,'debug')
        % DEBUG
        figure; subplot(2,2,1); hold on; title('Iterations converging on the ground plane.')
    end
    n_r2 = cell(N+1,1); n_r1 = cell(N+1,1);
    n_c2 = cell(N+1,size(cam2_dets_gnd,2)); n_c1 = cell(N+1,size(cam1_dets_gnd,1));
    for i=1:size(cam2_dets_cam,1)
      n_c2{1,i} = cam2_dets_gnd_original(i,:);
      n_c1{1,i} = cam1_dets_gnd_original(i,:);
    end
    region_shifts = zeros(N,1); region1_shift = 0; region2_shift = 0;
    distances = zeros(N,1); dd = zeros(N-1,1); distances_1 = zeros(N,1); distances_2 = zeros(N,1);

    noise = true;
    power = -100; % in dBs

    for reps = 1:N
        % "Fix" H1 and compute new H2
        if noise == true
            noise_mat_r = wgn(size(cam2_region_gnd,1), size(cam2_region_gnd,2), power);
            noise_mat_d = wgn(size(cam1_dets_gnd,1), size(cam1_dets_gnd,2), power);
        else
            noise_mat_r = zeros(size(cam2_region_gnd,1), size(cam2_region_gnd,2));
            noise_mat_d = zeros(size(cam1_dets_gnd,1), size(cam1_dets_gnd,2));
        end
        regdet_mat1 = vertcat(repmat(cam2_region_cam,rho_r,1), repmat(cam2_dets_cam,rho_d,1));
        regdet_mat2 = vertcat(repmat(cam2_region_gnd + noise_mat_r,rho_r,1), repmat(cam1_dets_gnd + noise_mat_d,rho_d,1));
        H2 = solve_homography(regdet_mat1, regdet_mat2, homog_solver);

        % "Fix" H2 and compute new H1
        if noise == true
            noise_mat_r = wgn(size(cam1_region_gnd,1), size(cam1_region_gnd,2), power);
            noise_mat_d = wgn(size(cam2_dets_gnd,1), size(cam2_dets_gnd,2), power);
        else
            noise_mat_r = zeros(size(cam1_region_gnd,1), size(cam1_region_gnd,2));
            noise_mat_d = zeros(size(cam2_dets_gnd,1), size(cam2_dets_gnd,2));
        end
        regdet_mat1 = vertcat(repmat(cam1_region_cam,rho_r,1), repmat(cam1_dets_cam,rho_d,1));
        regdet_mat2 = vertcat(repmat(cam1_region_gnd + noise_mat_r,rho_r,1), repmat(cam2_dets_gnd + noise_mat_d,rho_d,1));
        H1 = solve_homography(regdet_mat1, regdet_mat2, homog_solver);

        % Compute new cam2 ground plane regions and detections with n_H2
        %cam2_dets_gnd = H(n_H2,cam2_dets_cam);
        % NOTE I changed this from column wise to row wise
        for i=1:size(cam2_dets_cam,1)
          cam2_dets_gnd(i,:) = H(H2,transpose(cam2_dets_cam(i,:)));
          n_c2{reps+1,i} = cam2_dets_gnd(i,:);
        end
        %NOTE: There was a problem here with the clockwise ordenation of points, it made the method not converge
        cam2_region_gnd = reg2gnd(cam2_region_cam, H2);
        n_r2{reps+1} = cam2_region_gnd;
        % Compute new cam1 ground plane regions and detections with n_H1
        %cam1_dets_gnd = H(n_H1,cam1_dets_cam);
        for i=1:size(cam1_dets_cam,1)
          cam1_dets_gnd(i,:) = H(H1,transpose(cam1_dets_cam(i,:)));
          n_c1{reps+1,i} = cam1_dets_gnd(i,:);
        end
        cam1_region_gnd = reg2gnd(cam1_region_cam, H1);
        n_r1{reps+1} = cam1_region_gnd;
        if strcmp(debug,'debug') %DEBUG
            drawPoly(cam1_region_gnd,'Yellow',0.5,false); % Draw region
            drawPoly(cam2_region_gnd,'Pink',0.5,false); % Draw region
            scatter(cam1_dets_gnd(:,1),cam1_dets_gnd(:,2),'MarkerFaceColor',rgb('Yellow'),'MarkerEdgeColor',rgb('Yellow'));
            scatter(cam2_dets_gnd(:,1),cam2_dets_gnd(:,2),'MarkerFaceColor',rgb('Pink'),'MarkerEdgeColor',rgb('Pink'));
        end
        distances_1(reps) = pdist([cam2_dets_gnd(1,:); cam1_dets_gnd(1,:)]);
        distances_2(reps) = pdist([cam2_dets_gnd(2,:); cam1_dets_gnd(2,:)]);
        for i = 1:size(cam1_dets_gnd,1)
            distances(reps) = distances(reps) + pdist([cam2_dets_gnd(i,:); cam1_dets_gnd(i,:)]);
        end
        for i1=1:size(cam1_region_gnd,1)
            region1_shift = region1_shift + pdist([cam1_region_gnd(i,:); cam1_region_gnd_original(i,:)]);
        end
        region1_shift = region1_shift / i1;
        for i2=1:size(cam2_region_gnd)
            region2_shift = region2_shift + pdist([cam2_region_gnd(i,:); cam2_region_gnd_original(i,:)]);
        end
        region2_shift = region2_shift / i2;
        region_shifts(reps) = (region1_shift + region2_shift)/2;
        region1_shift = 0; region2_shift = 0;
        fprintf(['\t\t' num2str(distances(reps)) ' -- Iter ', num2str(reps),'| dist between gnd plane detections: \n']);
        if reps ~= 1
            dd(reps-1) = distances(reps-1) - distances(reps);
        end
        if dd(reps-1) < min_delta
            break;
        end
    end
    if strcmp(debug,'debug') %DEBUG
        hold on;
        for i = 1:size(cam1_dets_gnd,1)
            n_s1 = n_c1(:,i);
            n_s2 = n_c2(:,i);
            ns1 = cell2mat(n_s1);
            ns2 = cell2mat(n_s2);
            plot(ns1(:,1),ns1(:,2),'k');
            plot(ns2(:,1),ns2(:,2),'k');
        end

        drawPoly(cam1_region_gnd,'Orange',0.5,false); % Draw region
        drawPoly(cam2_region_gnd,'Purple',0.5,false); % Draw region
        scatter(cam1_dets_gnd_original(:,1),cam1_dets_gnd_original(:,2),'MarkerFaceColor',rgb('Orange'),'MarkerEdgeColor',rgb('Orange'));
        scatter(cam2_dets_gnd_original(:,1),cam2_dets_gnd_original(:,2),'MarkerFaceColor',rgb('Purple'),'MarkerEdgeColor',rgb('Purple'));
        xlabel('x(m)') % x-axis label
        ylabel('y(m)') % y-axis label

        subplot(2,2,2);
        plot(1:N,distances);
        title('Distance between adjusted matchings.')
        xlabel('N') % x-axis label
        ylabel('distance(m)') % y-axis label

        subplot(2,2,3);
        plot(1:N,region_shifts,'r');
        title('Avg distance shifts of camera regions.')
        xlabel('N') % x-axis label
        ylabel('shift(m)') % y-axis label

        subplot(2,2,4);
        plot(1:(N-1),dd,'g');
        title('Derivative of adjustments.')
        xlabel('N') % x-axis label
        ylabel('d(distance)/dN') % y-axis label
    end

    ns1 = cell2mat(n_c1);
    ns2 = cell2mat(n_c2);

    figure;
    hold on;
    plot(1:N,distances_1,'g');
    plot(1:N,distances_2,'m');
    legend('Pedestrian 1', 'Pedestrian 2');
    title('Distance between adjusted matchings for both pedestrians.')
    xlabel('N') % x-axis label
    ylabel('distance(m)') % y-axis label

    make_gif = 0;
    if make_gif == 1
        % NOTE Make GIFs of the detections (a gif per actual pedestrian)
        for i = 1:size(cam1_dets_gnd,1)
            figure;
            hold on;
            sz = 15;
            xlabel('x(m)') % x-axis label
            ylabel('y(m)') % y-axis label
            for reps = 1:N
                scatter(cam1_dets_gnd_original(i,1),cam1_dets_gnd_original(i,2),sz,'MarkerFaceColor',rgb('Orange'),'MarkerEdgeColor',rgb('Orange'));
                scatter(cam2_dets_gnd_original(i,1),cam2_dets_gnd_original(i,2),sz,'MarkerFaceColor',rgb('Purple'),'MarkerEdgeColor',rgb('Purple'));
                scatter(n_c1{reps+1,i}(:,1),n_c1{reps+1,i}(:,2),sz,'MarkerFaceColor',rgb('Red'),'MarkerEdgeColor',rgb('Yellow'));
                scatter(n_c2{reps+1,i}(:,1),n_c2{reps+1,i}(:,2),sz,'MarkerFaceColor',rgb('Blue'),'MarkerEdgeColor',rgb('Pink'));

                plot(ns1(1:reps+1,2*(i-1)+1),ns1(1:reps+1,2*(i-1)+2),'k');
                plot(ns2(1:reps+1,2*(i-1)+1),ns2(1:reps+1,2*(i-1)+2),'k');

                frame = getframe(gcf);
                img =  frame2im(frame);
                [img,cmap] = rgb2ind(img,256);
                if reps == 1
                   imwrite(img,cmap,strcat('pedestrian',num2str(i),'.gif'),'gif','LoopCount',Inf,'DelayTime',1);
                else
                   imwrite(img,cmap,strcat('pedestrian',num2str(i),'.gif'),'gif','WriteMode','append','DelayTime',1);
                end
            end

        end
        % NOTE Make GIFs of the regions
        figure;
        hold on;
        xlabel('x(m)') % x-axis label
        ylabel('y(m)') % y-axis label
        for reps = 1:N
            drawPoly(cam1_region_gnd,'Orange',1,false); % Draw region
            drawPoly(cam2_region_gnd,'Purple',1,false); % Draw region
            drawPoly(n_r1{reps+1},'Yellow',0.5,false); % Draw region
            drawPoly(n_r2{reps+1},'Pink',0.5,false); % Draw region
            frame = getframe(gcf);
            img =  frame2im(frame);
            [img,cmap] = rgb2ind(img,256);
            if reps == 1
               imwrite(img,cmap,'regions.gif','gif','LoopCount',Inf,'DelayTime',1);
            else
               imwrite(img,cmap,'regions.gif','gif','WriteMode','append','DelayTime',1);
            end
        end
    end
    % NOTE Put the output in cell_arrays
    Hs = cell(2,1); cam_dets_gnd = cell(2,1); cam_region_gnd = cell(2,1); n_c = cell(2,1);
    Hs{1} = H1; Hs{2} = H2;
    cam_dets_gnd{1} = cam1_dets_gnd; cam_dets_gnd{2} = cam2_dets_gnd;
    cam_region_gnd{1} = cam1_region_gnd; cam_region_gnd{2} = cam2_region_gnd;
    n_c{1} = n_c1; n_c{2} = n_c2;

end

function gpreg = reg2gnd(in_reg, h)
    s = size(in_reg,1);
    gpreg = zeros(s,2);
    for p=1:s
        pts = in_reg(p,:);
        gpreg(p,:) = H(h,pts');
    end
end
