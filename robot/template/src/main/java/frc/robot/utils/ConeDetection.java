package frc.robot.utils;

import java.util.ArrayList;

import org.opencv.core.Mat;
import org.opencv.core.MatOfPoint;
import org.opencv.core.MatOfPoint2f;
import org.opencv.core.Point;
import org.opencv.core.Rect;
import org.opencv.imgproc.Imgproc;

import edu.wpi.first.cameraserver.CameraServer;
import edu.wpi.first.cscore.CvSink;
import edu.wpi.first.cscore.CvSource;
import edu.wpi.first.cscore.UsbCamera;
import frc.robot.Constants.VisionConstants;
import frc.robot.Constants.coneOrientation;

public class ConeDetection{
    private GripPipeline findTotePipeline;
    private UsbCamera camera;
    private CvSink cvSink;
    private CvSource outputStream;
    private CvSource outputStream2;
    private Mat mat;
    private Thread visionThread;
    private coneOrientation result;

    public ConeDetection(){
        findTotePipeline = new GripPipeline();
        camera = CameraServer.startAutomaticCapture(1);
        mat = new Mat();
        result = null;
    }
    public void setVisionThread(){
        visionThread = new Thread(
      () -> {
        System.out.println("--------Go");
        
        
        System.out.println("------------UsbCamera on-----------");
        cvSink = CameraServer.getVideo(camera);
        outputStream = CameraServer.putVideo("Output", 640, 480);
        outputStream2 = CameraServer.putVideo("Output2", 640, 480);

        while (!Thread.interrupted()) {
          // Tell the CvSink to grab a frame from the camera and put it
          // in the source mat.  If there is an error notify the output.
          long grabResult = cvSink.grabFrame(mat);
          
          if (grabResult == 0) {
            // Send the output the error.
            outputStream.notifyError(cvSink.getError());
            // skip the rest of the current iteration
            continue;
          }
          else {   
            //Pipeline process
            camera.setResolution(VisionConstants.kIMG_WIDTH, VisionConstants.kIMG_HEIGHT);

            System.out.println("---------pipeline run---------");
            findTotePipeline.process(mat);
            ArrayList<MatOfPoint> countoursOutput = findTotePipeline.filterContoursOutput();
            System.out.println(countoursOutput.get(0));
            System.out.println("---------pipeline end---------");
            Rect rect = Imgproc.boundingRect(countoursOutput.get(0));

            int centerY = rect.y+(rect.height / 2);
            int divideX = rect.width/8;

            MatOfPoint2f countoursOutput2F = new MatOfPoint2f(countoursOutput.get(0).toArray());
            double[] pointsHeight = new double[4];

            for(int x=0;x<4;x++){
              double y1=0;
              double y2=0;
              for(int i=0;i<rect.height;i++){
                Point temp1 = new Point(rect.x + (rect.width/4) + divideX*x, centerY-i);
                if (Imgproc.pointPolygonTest(countoursOutput2F, temp1, false)==1){
                  y1=temp1.y;
                }

                Point temp2 = new Point(rect.x + (rect.width/4) + divideX*x, centerY+i);
                if (Imgproc.pointPolygonTest(countoursOutput2F, temp2, false)==1){
                  y2=temp2.y;
                }
              }
              pointsHeight[x]=y2-y1;
            }
            
            for(int h=1;h<4;h++){
              if(pointsHeight[h]>pointsHeight[h-1]){
                result=coneOrientation.LEFT;
              }else{
                result=coneOrientation.RIGHT;
              }
            }
            if(Math.abs(pointsHeight[0]-pointsHeight[3])<rect.height/8){
              result=null;
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
    }
    
    public coneOrientation getResult(){
        return result;
    }

    public Thread getVisionThread(){
        return visionThread;
    }

    public void startVisionThread(){
        visionThread.setDaemon(true);
        visionThread.start(); 
    }
}  

