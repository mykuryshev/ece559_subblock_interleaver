clear;
%%simulate the expected output result when given one of two block sizes
% bit blocks of size 6144 (or 1056, but fixed for this code at least)
% randomize to zeros of ones, split by mod3 into 3 blocks by row width 32
% then column
%permute blocks
%output bit by bit per block, first by permuted column, then row...

%generate block
%ONLY CHANGE THE NUMBER BEFORE '*3' OR REMEMBER IT WILL BE SPLIT TO 3
%BLOCKS
block_size = 32;
%%random number input
in_block = randi(2, block_size, 1, 3);
in_block = in_block-1;

%1010101010 input
% in_block=zeros(1,block_size,3);
% for i =1:block_size
%    in_block(1,i,:)=mod(i,2);
% end


%split block by mod3 result into 3 smaller sub-subblocks
%subblocks = zeros(1, block_size, 3);

%pass values into the subblocks
% i=1;
% for c = 1:block_size
%     x=mod(c,3);
%     if (x==0)
%         x=3;
%     end
%     subblocks(1,i,x) = in_block(c);
%     if (x==3)
%         i=i+1;
%     end
% end

%reshape subblocks into size/32, 32, 3 form
num_rows = block_size/32;

permuted = reshape(in_block, [num_rows,32,3]);

%permute by our method
perm_ind = [1 17 9 25 5 21 13 29 3 19 11 27 7 23 15 31 2 18 10 26 6 22 14 30 4 20 12 28 8 24 16 32];
%histc(perm_ind, unique(perm_ind)) %to check hardcoding permutation ok
permuted = permuted(:,perm_ind,:);

%producing the output, vectorizing 3d stuff in a specific direction oh boy...
permuted_v = zeros(1,block_size,3);
for c=1:3
    x = permuted(:,:,c);
    permuted_v(1,1:block_size,c) = x(:)';
end

%final output
output = zeros(1,block_size*3);
i=1;
for c=1:block_size
    for d=1:3
        output(1,i) = permuted_v(1,c,d);
        i=i+1;
    end
end
   
