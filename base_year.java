 public void get_baseyear()
	 {		 		 
		 	get_lang();	
		 	int byearValue = 100;	
		 	double[] byearVal = null;	
		 	double b_val;
			String[][] ob1 ;
			Observation obs = null;
			ObservationList obsList1 = null;
			ObservationList[] obsList2 = null;
			obsList2 = new ObservationList[tiqObject.length];
			String [] dates2;
			String[] sum_m_val;
			double sum_val = 0;
			double[] d_val = null;
			Integer new_base_year = new Integer(byear);
			Integer base_first_month = new Integer(1);
			Integer base_last_month = new Integer(12);
			Integer base_first_day = new Integer(1);
			int start_b_yr = new_base_year.intValue();
			int start_f_m = base_first_month.intValue();
			int start_l_m = base_last_month.intValue();
			int start_b_d = base_first_day.intValue();
			TiqFrequency tiqfrequency;
			char chr;
			Character character;
			String findFreq = null;
			String [][] twoArrays;
			String[] tiqVal = null;
			String datePattern = "MMMyyyy";
			TiqDateFormat tdf = new TiqDateFormat(datePattern);
			
			byearIdx = DateHelper.ymdToIndex(start_b_yr, 1 , 1);
			byearStartIdx = DateHelper.ymdToIndex(start_b_yr, start_f_m, start_b_d);
			byearEndIdx = DateHelper.ymdToIndex(start_b_yr, start_l_m, start_b_d);
						
				// Retrieve observations of tiqobject
			System.out.println(obsList2.length + " length");
			
			
			
				for(int i = 0; i < tiqObject.length; i++)
				{
					obsList2[i] = tiqObject[i].getObservations();
				}
				
				int i = tiqObject.length;
				int j = obsList2[0].size();
				twoArrays = new String[i][j];
				ob1 = new String[i][j];
				twoArrays = new String[i][j];
				dates2 = new String[j];
				byearObj = new TiqObject[tiqObject.length];			
				try {					
					for (int i1 = 0; i1 < tiqObject.length; i1++)
					{								
						obsList1 = tiqObject[i1].getObservations(byearStartIdx, byearEndIdx);
						
						try {
							obs = tiqObject[i1].getObservation(byearIdx);

						} catch (DateAlignmentChkException e) {
							e.printStackTrace();
						}										
			
						obsList2[i1] = tiqObject[i1].getObservations();
						sum_m_val = obsList1.getValues().getStringArray();
						b_val = obs.getDoubleValue();

						//tiqfrequency = obsList2.getFrequency();
						tiqfrequency = obsList2[i1].getFrequency();
						chr = tiqfrequency.encode();
						character = new Character(chr);
						findFreq = character.toString();
						
						if (findFreq.equals("M"))
						{
							d_val = new double[sum_m_val.length];
							sum_val = 0;
							for (int j1 = 0; j1 < d_val.length; j1++)
							{
								d_val[j1] = Double.parseDouble(sum_m_val[j1]);
								sum_val += d_val[j1] / 12;
							}
						}// end if
						else if(findFreq.equals("Q"))
						{
							d_val = new double[sum_m_val.length];
							sum_val = 0;							
							for (int j1 = 0; j1 < d_val.length; j1++)
							{
								d_val[j1] = Double.parseDouble(sum_m_val[j1]);
								sum_val += d_val[j1] / 4;
							}
						}
						else if (findFreq.equals("A"))
						{
							sum_val = b_val;
						}
											
						ob1[i1] = obsList2[i1].getValues().getStringArray();
						dates2 = obsList2[i1].getIndexesAsStrings();
						byearVal = new double[ob1[0].length];
						tiqVal = new String[byearVal.length];
														
						for(int k = 0; k < ob1[0].length; k++)
						{
							byearVal[k] = Double.parseDouble(ob1[i1][k]);
							byearVal[k] = byearVal[k] / sum_val * byearValue;
							tiqVal[k] = twoDigits.format(byearVal[k]);
							twoArrays[i1][k] = tiqVal[k];				
						}													
						
						long[] dateIndex = new long[dates2.length];
						//long[] dateIndex = new long[myIndex.length];
						float[] dataValue = new float[tiqVal.length];
						byte[] bytes = new byte[dates2.length];
						//byte[] bytes = new byte[myIndex.length];

						for ( int lcv = 0; lcv < dateIndex.length; lcv++)
						{
							dateIndex[lcv] = DateHelper.javaDateToIndex(tdf.parse(dates2[lcv],new ParsePosition(0)), null);
							//dateIndex[lcv] = DateHelper.javaDateToIndex(tdf.parse(myIndex[lcv],new ParsePosition(0)), null);
							bytes[lcv] = Observation.STATUS_OK;
							tiqVal[lcv] = tiqVal[lcv].replace(",", ".");
							dataValue[lcv] = new Float(tiqVal[lcv]).floatValue();
						}
						FloatList floatList = new FloatList(dataValue);		
						
						RegularCalendar rc = null;
						
						if(findFreq.equals("M"))
						{
							//sc = new SimpleCalendar(TiqFrequency.MONTHLY, SimpleCalendar.REF_DECEMBER,1);
							CalendarFactory cf = CalendarFactory.getInstance();
							rc = cf.getCalendar(TiqFrequency.MONTHLY, SimpleCalendar.REF_DECEMBER,1);
							
							obsList = new ObservationList(dateIndex, floatList, bytes, TiqFrequency.MONTHLY);
						}
						else if(findFreq.equals("Q"))
						{
							//sc = new SimpleCalendar(TiqFrequency.QUARTERLY, SimpleCalendar.REF_JANUARY,1);
							CalendarFactory cf = CalendarFactory.getInstance();
							rc = cf.getCalendar(TiqFrequency.QUARTERLY, SimpleCalendar.REF_JANUARY,1);
							obsList = new ObservationList(dateIndex, floatList, bytes, TiqFrequency.QUARTERLY);
						}
						else if(findFreq.equals("A"))
						{
							//sc = new SimpleCalendar(TiqFrequency.ANNUAL, SimpleCalendar.REF_JANUARY, 1);
							CalendarFactory cf = CalendarFactory.getInstance();
							rc = cf.getCalendar(TiqFrequency.ANNUAL, SimpleCalendar.REF_JANUARY, 1);
							obsList = new ObservationList(dateIndex, floatList, bytes, TiqFrequency.ANNUAL);
						}											
						//RegularSeries rs = new RegularSeries(sc,obsList);
						RegularSeries rs = new RegularSeries(rc, obsList);
						byearObj[i1] = rs;
						//byearObj[i1] = byearObj[i1].getTiqObjectCopy(startIndex, endIndex);
											
					}// end outer for 
					
			}catch (RangeTooLargeChkException e) {
				e.printStackTrace();
			}	 
	 }// end get_baseyear