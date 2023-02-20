package frc.robot.utils;

import java.util.ArrayList;

public final class ArrayPool {

	private ArrayPool() {}

	private static final ArrayList<double[]> list = new ArrayList<>();

	public static double[] reserve(int length) {
		for (int i = 0; i < list.size(); i++) {
			double[] array = list.get(i);
			if (array.length == length) {
				list.remove(i);
				return array;
			}
		}
		return new double[length];
	}

	public static void release(double[] array) {
		if (array == null)
			throw new IllegalArgumentException("array is null");
		list.add(array);
	}
}
