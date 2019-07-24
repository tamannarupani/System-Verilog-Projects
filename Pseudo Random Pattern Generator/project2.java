package project2;
import java.io.BufferedReader;
import java.io.FileReader;
import java.io.IOException;
import java.util.ArrayList;

public class project2{
	public static void main(String[] args) throws IOException {
		ArrayList<Integer> code32bit = new ArrayList<Integer>();
		ArrayList<Integer> operation = new ArrayList<Integer>();
		ArrayList<Integer> register = new ArrayList<Integer>();
		ArrayList<Integer> location = new ArrayList<Integer>();
		ArrayList<Integer> tap = new ArrayList<Integer>();
		ArrayList<Integer> seed = new ArrayList<Integer>();
		ArrayList<Integer> num = new ArrayList<Integer>();
		int decimalRegister = 0;
		int decimalNum = 0;
		int op = 0;
		ArrayList<Integer> Q = new ArrayList<Integer>();
		ArrayList<Integer> output = new ArrayList<Integer>();
		ArrayList<Integer> previousQ = new ArrayList<Integer>();
		ArrayList<ArrayList<Integer>> memory = new ArrayList<ArrayList<Integer>>();
		String file="lfst_t1.txt";
		String l = null;
		FileReader f = new FileReader(file);
		BufferedReader b = new BufferedReader(f);
		char[] code32bitCharacterArray = null;
		for(int i=0; i<8; i++){
			previousQ.add(0);
			seed.add(0);
			output.add(0);
			Q.add(0);
			location.add(0);
			register.add(0);
			num.add(0);
		}
		for(int i=0; i<6; i++){
			operation.add(0);
		}
		for(int i=0; i<7; i++){
			tap.add(0);
		}
		for(int i=0; i<32; i++){
			code32bit.add(0);
		}
		for(int i=0; i<1000; i++){
			memory.add(Q);
		}
		while((l = b.readLine())!= null){
		code32bitCharacterArray = l.toCharArray();
		for(int i=0; i<code32bitCharacterArray.length; i++){
			code32bit.set(i, code32bitCharacterArray[i] - '0');
		}
		for(int i = 0; i<6; i++){
			operation.add(i,code32bit.get(i));
		}
		for(int i=0; i<6; i++){
			op = (int) (op + operation.get(5-i)*Math.pow(2, i));
		}
		if(op==1){
			for(int i=0; i<7; i++){
				tap.set(i,code32bit.get(i+25));
			}	
		}
		else if(op==2){
			for(int i=0; i<8; i++){
				seed.set(i,code32bit.get(i+14));
				output.set(i,seed.get(i));
				previousQ.set(i,seed.get(i));
			}
		}
		else if(op==3){
			Q.set(0, previousQ.get(7));
			for(int i=1; i<8; i++){
				if(tap.get(i-1) == 1){
					
					Q.set(i,((previousQ.get(i-1))^(previousQ.get(7))));
				}
				else{
					Q.set(i,(previousQ.get(i-1)));
				}
			}
			for(int i=0; i<8; i++){
				output.set(i, Q.get(i));
				previousQ.set(i, Q.get(i));
			}
		}
		else if(op==6){
			for(int i=0; i<8; i++){
				location.add(i,code32bit.get(i+6));
				register.set(i, location.get(i));
			}
		}
		else if(op==4){
			for(int i=0; i<8; i++){
				decimalRegister = (int) (decimalRegister + register.get(7-i)*Math.pow(2, i));
			}
			memory.set(decimalRegister,output);
			System.out.print("Memory Content:"+memory.get(decimalRegister));
		}
		else if(op==5){
			 ArrayList<Integer> x = new ArrayList<Integer>();
			 x = memory.get(decimalRegister);
			 for(int i=0; i<8; i++){
				seed.set(i,(x.get(i)));
			}
		}
		else if(op==7){
			for(int i=0; i<8; i++){
				num.set(i,code32bit.get(i+14));
			}
			for(int i=0; i<8; i++){
				decimalRegister = (int) (decimalRegister + register.get(7-i)*Math.pow(2, i));
			}
			for(int i=0; i<8; i++){
				decimalNum = (int) (decimalNum + num.get(i)*Math.pow(2, i));
			}
			decimalRegister  = decimalRegister + decimalNum;
			System.out.print("Memory - "+memory.get(decimalRegister));
		}
		System.out.println("LFSR  - "+output);
		operation.clear();
		location.clear();
		op = 0;
		decimalNum = 0;
		decimalRegister = 0;
		
		}
		b.close();
		f.close();
	}

}


