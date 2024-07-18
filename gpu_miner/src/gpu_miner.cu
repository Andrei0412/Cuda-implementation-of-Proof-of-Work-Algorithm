#include <stdio.h>
#include <stdint.h>
#include "../include/utils.cuh"
#include <string.h>
#include <stdlib.h>
#include <inttypes.h>

__device__ int foundFlag = 0;
#define NUM_BLOCKS 256
#define NUM_THREADS 512

__global__ void findNonce(BYTE *block_hash, uint64_t *nonce, size_t *current_length, BYTE *block_content) {
	uint64_t index = blockIdx.x * blockDim.x + threadIdx.x;
	if (index == 0) index ++;
	uint64_t stride = blockDim.x * gridDim.x;

	char nonce_string[NONCE_SIZE];
	BYTE gpu_block_hash[SHA256_HASH_SIZE];
	BYTE gpu_block_content[BLOCK_SIZE];
	BYTE my_diff[SHA256_HASH_SIZE] = "0000099999999999999999999999999999999999999999999999999999999999";
	memcpy(gpu_block_content, block_content, BLOCK_SIZE * sizeof(BYTE));

  	for (u_int64_t i = index; i <= MAX_NONCE; i+= stride) {
		if (foundFlag == 0) {
			int length = intToString(i, nonce_string);
        	d_strcpy((char*) gpu_block_content + *current_length, nonce_string);
        	apply_sha256(gpu_block_content, d_strlen((const char*)gpu_block_content), gpu_block_hash, 1);

        	if (compare_hashes(gpu_block_hash, my_diff) <= 0) {
				atomicExch(&foundFlag, 1);
				*nonce = i;
				memcpy(block_hash, gpu_block_hash, SHA256_HASH_SIZE * sizeof(BYTE));
            	break;
        	}
		} else {
			break;
		}
	}

	if (foundFlag != 0) {
		return;
	}

	return;
}

int main(int argc, char **argv) {
	BYTE hashed_tx1[SHA256_HASH_SIZE], hashed_tx2[SHA256_HASH_SIZE], hashed_tx3[SHA256_HASH_SIZE], hashed_tx4[SHA256_HASH_SIZE],
			tx12[SHA256_HASH_SIZE * 2], tx34[SHA256_HASH_SIZE * 2], hashed_tx12[SHA256_HASH_SIZE], hashed_tx34[SHA256_HASH_SIZE],
			tx1234[SHA256_HASH_SIZE * 2], top_hash[SHA256_HASH_SIZE];

	BYTE *block_hash;
	uint64_t *nonce;
	size_t *current_length;
	BYTE *block_content;
	cudaMallocManaged(&block_hash, SHA256_BLOCK_SIZE * sizeof(BYTE));
  	cudaMallocManaged(&nonce, sizeof(uint64_t));
	cudaMallocManaged(&current_length, sizeof(size_t));
	cudaMallocManaged(&block_content, BLOCK_SIZE * sizeof(BYTE));

	// Top hash
	apply_sha256(tx1, strlen((const char*)tx1), hashed_tx1, 1);
	apply_sha256(tx2, strlen((const char*)tx2), hashed_tx2, 1);
	apply_sha256(tx3, strlen((const char*)tx3), hashed_tx3, 1);
	apply_sha256(tx4, strlen((const char*)tx4), hashed_tx4, 1);
	strcpy((char *)tx12, (const char *)hashed_tx1);
	strcat((char *)tx12, (const char *)hashed_tx2);
	apply_sha256(tx12, strlen((const char*)tx12), hashed_tx12, 1);
	strcpy((char *)tx34, (const char *)hashed_tx3);
	strcat((char *)tx34, (const char *)hashed_tx4);
	apply_sha256(tx34, strlen((const char*)tx34), hashed_tx34, 1);
	strcpy((char *)tx1234, (const char *)hashed_tx12);
	strcat((char *)tx1234, (const char *)hashed_tx34);
	apply_sha256(tx1234, strlen((const char*)tx34), top_hash, 1);

	// prev_block_hash + top_hash
	strcpy((char*)block_content, (const char*)prev_block_hash);
	strcat((char*)block_content, (const char*)top_hash);
	*current_length = strlen((char*) block_content);

	cudaEvent_t start, stop;
	startTiming(&start, &stop);

	findNonce<<<NUM_BLOCKS, NUM_THREADS>>>(block_hash, nonce, current_length, block_content);
	cudaDeviceSynchronize();

	float seconds = stopTiming(&start, &stop);
	printResult(block_hash, *nonce, seconds);

	cudaFree(block_hash);
  	cudaFree(nonce);
  	cudaFree(current_length);
  	cudaFree(block_content);

	return 0;
}
