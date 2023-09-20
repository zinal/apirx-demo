package demo1;

/**
 *
 * @author zinal
 */
public class Calc1Test {

    public long calcMe(long threadNum, long cntBig) {
        long cntMax = 1000;
        long tokens = 1000;
        return tokens * ((threadNum * cntMax) + cntBig);
    }

    public void test1() {
        System.out.println("0, 0 -> " + calcMe(0, 0));
        System.out.println("1, 0 -> " + calcMe(1, 0));
        System.out.println("2, 0 -> " + calcMe(2, 0));
        System.out.println("99, 0 -> " + calcMe(99, 0));
    }

    public void test2() {
        System.out.println("0, 1 -> " + calcMe(0, 1));
        System.out.println("0, 2 -> " + calcMe(0, 2));
        System.out.println("0, 99 -> " + calcMe(0, 99));
        System.out.println("15, 1 -> " + calcMe(15, 1));
        System.out.println("15, 2 -> " + calcMe(15, 2));
        System.out.println("15, 99 -> " + calcMe(15, 99));
        System.out.println("99, 999 -> " + calcMe(99, 999));
    }

}
