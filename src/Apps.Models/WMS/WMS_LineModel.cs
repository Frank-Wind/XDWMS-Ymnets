﻿using System;
using System.ComponentModel.DataAnnotations;
using Apps.Models;
namespace Apps.Models.WMS
{
    public partial class WMS_LineModel
    {
        [Display(Name = "类别名称")]
        public string HeaderName { get; set; }
     }
}

