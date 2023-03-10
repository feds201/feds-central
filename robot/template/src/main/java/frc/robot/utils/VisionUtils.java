package frc.robot.utils;

import org.opencv.core.Mat;
import org.opencv.imgproc.*;

import java.util.ArrayList;

import org.opencv.core.*;

import edu.wpi.first.cameraserver.CameraServer;
import edu.wpi.first.cscore.CvSink;
import edu.wpi.first.cscore.CvSource;
import edu.wpi.first.cscore.UsbCamera;

public class VisionUtils {
    public static Thread makeGripThread(int cameraID) {
        Thread visionThread = new Thread(
                () -> {
                    System.out.println("--------Go");
                    UsbCamera camera = CameraServer.startAutomaticCapture(1);

                    System.out.println("------------UsbCamera on-----------");
                    CvSink cvSink = CameraServer.getVideo(camera);
                    CvSource outputStream = CameraServer.putVideo("Output", 192, 144);
                    CvSource outputStream2 = CameraServer.putVideo("Output2", 192, 144);
                    Mat mat = new Mat();

                    while (!Thread.interrupted()) {
                        // Tell the CvSink to grab a frame from the camera and put it
                        // in the source mat. If there is an error notify the output.
                        long grabResult = cvSink.grabFrame(mat);
                        if (grabResult == 0) {
                            // Send the output the error.
                            outputStream.notifyError(cvSink.getError());
                            // skip the rest of the current iteration
                            continue;
                        } else {
                          
                            // Pipeline process
                            // camera.setResolution(192, 144);

                            System.out.println("---------pipeline run---------");
                            GripPipeline findTotePipeline = new GripPipeline();
                            findTotePipeline.process(mat);


                            ArrayList<MatOfPoint> countoursOutput;
                            boolean isCone = true;
                            if(findTotePipeline.filterContours0Output().isEmpty()){
                              countoursOutput = findTotePipeline.filterContours1Output();
                            }else{
                              countoursOutput = findTotePipeline.filterContours0Output();
                              isCone=false;
                            }


                            System.out.println(countoursOutput.get(0));
                            System.out.println("---------pipeline end---------");
                            Rect rect = Imgproc.boundingRect(countoursOutput.get(0));

                            int centerY = rect.y + (rect.height / 2);
                            int centerX = rect.x + (rect.width / 2);
                            

                            String result = "";

                            if(isCone){
                              int divideX = rect.width / 8;
                              MatOfPoint2f countoursOutput2F = new MatOfPoint2f(countoursOutput.get(0).toArray());
                              double[] pointsHeight = new double[4];

                              for (int x = 0; x < 4; x++) {
                                  double y1 = 0;
                                  double y2 = 0;
                                  for (int i = 0; i < rect.height; i++) {
                                      Point temp1 = new Point(rect.x + (rect.width / 4) + divideX * x, centerY - i);
                                      if (Imgproc.pointPolygonTest(countoursOutput2F, temp1, false) == 1) {
                                          y1 = temp1.y;
                                      }

                                      Point temp2 = new Point(rect.x + (rect.width / 4) + divideX * x, centerY + i);
                                      if (Imgproc.pointPolygonTest(countoursOutput2F, temp2, false) == 1) {
                                          y2 = temp2.y;
                                      }
                                  }
                                  pointsHeight[x] = y2 - y1;
                              }

                              for (int h = 1; h < 4; h++) {
                                  if (pointsHeight[h] > pointsHeight[h - 1]) {
                                      result = "Left";
                                  } else {
                                      result = "Right";
                                  }
                              }
                              if (Math.abs(pointsHeight[0] - pointsHeight[3]) < rect.height / 8) {
                                  result = centerX+" "+centerY;
                              }
                            }else{
                              result = centerX+" "+centerY;
                            }

                            System.out.println(result);

                            System.out.println("---------Output is:---------");
                            // System.out.println(rect);
                            // outputStream.putFrame(mat);
                            outputStream.putFrame(findTotePipeline.rgbThresholdOutput());
                            outputStream2.putFrame(mat);
                        }
                    }
                });
        return visionThread;
    }
}