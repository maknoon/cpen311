#define switches (volatile unsigned char *) 0x0002040 
#define leds (char *) 0x0002030
#define out_out (char *) 0x0002020
#define done (char *) 0x0002010
#define ledg (char *) 0x0002000

// http://stackoverflow.com/questions/1801391/
void isPrime(unsigned int *num) {
   int a1 = 2;
   
   if (*num <= 3) { *ledg = 1; }
   else if (*num % 2 == 0) { *ledg = 2; }
   else if (*num % 3 == 0) { *ledg = 2; }
   else { 
      while (a1 < *num) {
         if (*num % a1 == 0) { 
	   *ledg = 2;
	   break;
         } else { *ledg = 1; }
	 a1 += 1;
      }
   }
}

void main()
{
   unsigned int *sum;
   *done = 0;
   *ledg = 0;
   
   while (1) {
       *leds = *switches;
       // for task3: display the adder
       *out_out = (*switches)/16 + (*switches)%16;
       *sum = *out_out;
       isPrime(sum);
       if (*ledg != 0) { *done = 1; }
   }
}
