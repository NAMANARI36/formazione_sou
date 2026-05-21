using System;
using System.Collections.Generic;

class Program
{
    static void Main()
    {
        string[] arrayDichiarativo = { "Geppetto", "Gabriele", "VAlerio", "GiuLIA", "FABIANO", "MeRiSiTa", "Annie", "Jenny", "GEPPETTO", "Valerio", "Fabiano" };

        HashSet<string> hashset = new HashSet<string>();

        foreach (string stringa in arrayDichiarativo)
        {
            hashset.Add(stringa.ToLower());
        }

        foreach (string stringa in hashset)
        {
            Console.WriteLine(stringa);
        }
    }
}
