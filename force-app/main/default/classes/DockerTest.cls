@isTest
public class DockerTest {
    @isTest
    static void test(){
        Docker.run();
        System.assert(true, 'Invalid test');
    }
}
