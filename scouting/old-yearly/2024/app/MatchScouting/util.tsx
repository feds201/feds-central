export const mapIndexToData = (d:any, index: number, arr: any[]) => {
    return {
        text: `${index}`,
        key: `${index}`
    };
}

export type Item = ReturnType<typeof mapIndexToData>;
