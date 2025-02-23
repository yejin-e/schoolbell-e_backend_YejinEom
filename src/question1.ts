function findCombination(arr: number[]): [number, number] {
    const sortedAarr = [...arr].sort((a: number, b: number): number => b-a);    // 원본 배열을 복사하고 내림차순으로 정렬
    let [num1, num2]: [number, number] = [sortedAarr[0], sortedAarr[1]];        // 정렬된 배열에서 가장 큰 두 숫자를 초기값으로 설정      

    for (const x of sortedAarr.slice(2)){   // 남은 숫자들을 순회
        if (num1 > num2){                   // 더 작은 숫자에 현재 숫자를 붙여 큰 수를 만듦
            num2 = num2 * 10 + x;
        }
        else{
            num1 = num1 * 10 + x;
        }       
    }

    return [num1, num2];
}


const [num1, num2]: [number, number] = findCombination([1, 3, 5, 7, 9]);
console.log(`result: ${num1}, ${num2}`);
