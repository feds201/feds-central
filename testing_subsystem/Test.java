public class Test {

    Public enum testState() {
        TESTINTAKE,
        TESTSHOOTER, 
        TESTSPINDEXER,
        TESTKICK,
        TESTLL
    }


     public void setState(IntakeState targetState) {
    this.targetState = targetState; 
    this.currentState = targetState;
  }

}
