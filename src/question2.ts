function dfs(i: number): void {
    islands[i] = false;      // 방문한 곳 체크 (섬을 바다로 변경)

    for (const d of directions) {
        if (i%w === 0 && (d === -w-1 || d === -1 || d === w-1))   continue;   // 현재 위치가 좌측 경계이고 왼쪽으로 이동하려는 경우 건너뛰기
        if (i%w === w-1 && (d === -w+1 || d === 1 || d === w+1))  continue;   // 현재 위치가 우측 경계이고 오른쪽으로 이동하려는 경우 건너뛰기

        const newI = i+d;               // 새로운 인덱스 계산 후 유효한지 확인
        if (0 <= newI && newI < w*h     // 배열 범위 내에 있는지 확인    
            && islands[newI]) {         // 새 위치가 섬인지 확인
            dfs(newI);                  // 새 위치에서 DFS 계속 진행
        }
    }
}


function countIslands(): number {
    let cnt: number = 0;

    for (let i = 0; i < islands.length; i++) {
        if (islands[i]){            // 현재 위치가 섬이면
            dfs(i);
            cnt += 1;               // 섬 개수 증가
        }
    }
    return cnt;
}


const islands: boolean[] = [
    true, false, true, false, false,
    true, false, false, false, false,
    true, false, true, false, true,
    true, false, false, true, false
]                                           // Land: true, Sea: false로 설정
const [w, h]: [number, number] = [5, 4];
const directions: number[] = [-w-1, -w, -w+1, -1, 1, w-1, w, w+1]     // 8방향(상하좌우 및 대각선)으로의 이동을 나타내는 배열


console.log('result:', countIslands());
