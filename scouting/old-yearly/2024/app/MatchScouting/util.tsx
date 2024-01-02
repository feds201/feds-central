export function getColor(i: number, numItems: number) {
    const multiplier = 255 / (numItems - 1);
    const colorVal = i * multiplier;
    return `rgb(${colorVal}, ${Math.abs(128 - colorVal)}, ${255 - colorVal})`;
}

export const getRandColorVal = () => Math.floor(Math.random() * 255);

export const mapIndexToData = (d: any, index: number, arr: any[]) => {
    const backgroundColor = getColor(index, arr.length);
    return {
        text: `${index}`,
        key: `key-${backgroundColor}`,
        backgroundColor,
    };
}

export type Item = ReturnType<typeof mapIndexToData>;
